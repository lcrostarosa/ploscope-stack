# Backend Integration Guide for Celery Worker

## Overview

The Celery worker consumes jobs from RabbitMQ queues and processes them. This guide explains how the backend should publish jobs to ensure proper message format and delivery.

## Queue Architecture

### Main Queues (on `plosolver` exchange)
- `spot-processing` - For spot simulation jobs
- `solver-processing` - For solver analysis jobs

### Dead Letter Queues (on `plosolver-dlx` exchange)
- `spot-processing-dlq` - Failed spot simulation jobs
- `solver-processing-dlq` - Failed solver analysis jobs

### Retry Behavior
- Tasks will automatically retry up to **3 times** with exponential backoff
- After 3 failed attempts, the worker rejects without requeue and the message moves to the DLQ
- Messages in DLQ can be manually reprocessed or inspected
- **Important**: Tasks must raise exceptions (not return error responses) for retry/DLQ to work

## How to Publish Jobs (IMPORTANT)

**❌ DO NOT manually publish to RabbitMQ queues**

**✅ USE Celery's send_task() method**

### Why?
Celery requires a specific message protocol that includes:
- Task name
- Arguments
- Task ID
- Metadata (retries, callbacks, etc.)
- Proper headers

If you publish raw JSON like `{'job_id': '...', 'job_type': '...'}`, Celery will reject it with:
```
WARNING/MainProcess] Received and deleted unknown message. Wrong destination?!?
```

## Implementation

### Option 1: Using Celery Client (Recommended)

```python
from celery import Celery
import os

# Initialize Celery (just for sending tasks)
celery = Celery(
    broker=os.environ.get(
        'CELERY_BROKER_URL',
        'amqp://plosolver:dev_password_2024@rabbitmq:5672/%2Fplosolver'
    )
)

# Send spot simulation job
def send_spot_simulation_job(job_id: str):
    celery.send_task(
        'celery_worker.tasks.process_spot_simulation',
        args=[job_id],
        queue='spot-processing'
    )

# Send solver analysis job
def send_solver_analysis_job(job_id: str):
    celery.send_task(
        'celery_worker.tasks.process_solver_analysis',
        args=[job_id],
        queue='solver-processing'
    )
```

### Option 2: Manual Message Format (If you can't use Celery)

If you absolutely cannot use the Celery Python client, you must publish messages in this format:

```python
import json
import uuid
import pika

# Message body
message = {
    "task": "celery_worker.tasks.process_spot_simulation",  # Full task path
    "id": str(uuid.uuid4()),  # Unique task ID
    "args": [job_id],  # job_id as first argument
    "kwargs": {},
    "retries": 0,
    "eta": None,
    "expires": None,
    "callbacks": None,
    "errbacks": None,
    "timelimit": [None, None],
    "taskset": None,
    "chord": None
}

# Publish to RabbitMQ
connection = pika.BlockingConnection(
    pika.ConnectionParameters(
        host='rabbitmq',
        port=5672,
        virtual_host='/plosolver',
        credentials=pika.PlainCredentials('plosolver', 'dev_password_2024')
    )
)
channel = connection.channel()

channel.basic_publish(
    exchange='plosolver',
    routing_key='spot-processing',
    body=json.dumps(message),
    properties=pika.BasicProperties(
        content_type='application/json',
        content_encoding='utf-8',
        delivery_mode=2,  # Persistent
    )
)
```

## Task Signatures

### process_spot_simulation
```python
@celery.task(bind=True, max_retries=3)
def process_spot_simulation(self, job_id: str):
    """
    Process a spot simulation job.

    Args:
        job_id (str): The UUID of the job to process

    Returns:
        dict: {"status": "completed|failed", "result": {...}, "error": "..."}
    """
```

**What it does:**
1. Fetches job from database by `job_id`
2. Updates job status to PROCESSING
3. Performs double board PLO simulation
4. Saves results to database
5. Returns completion status

### process_solver_analysis
```python
@celery.task(bind=True, max_retries=3)
def process_solver_analysis(self, job_id: str):
    """
    Process a solver analysis job.

    Args:
        job_id (str): The UUID of the job to process

    Returns:
        dict: {"status": "completed|failed", "solution": {...}, "error": "..."}
    """
```

**What it does:**
1. Fetches job from database by `job_id`
2. Updates job status to PROCESSING
3. Runs solver analysis
4. Saves solution to database
5. Returns solution

## Environment Variables (Backend)

Make sure these are set in your backend environment:

```bash
# RabbitMQ Connection
CELERY_BROKER_URL=amqp://plosolver:dev_password_2024@rabbitmq:5672/%2Fplosolver

# Queue Names (must match worker config)
RABBITMQ_SPOT_QUEUE=spot-processing
RABBITMQ_SOLVER_QUEUE=solver-processing
RABBITMQ_SPOT_DLQ=spot-processing-dlq
RABBITMQ_SOLVER_DLQ=solver-processing-dlq
```

## RabbitMQ Optional Policy (server-side DLQ after delivery limit)

If you prefer RabbitMQ to move messages to DLQ after a delivery attempt limit (extra safety), set a policy on your main queues:

```bash
rabbitmqctl set_policy \
  dlq-after-delivery-limit \
  "^(spot-processing|solver-processing)$" \
  '{"dead-letter-exchange":"plosolver-dlx","delivery-limit":4}' \
  --apply-to queues
```

Notes:
- delivery-limit includes the first delivery; with 4, you'll get up to 3 retries. Align with Celery `max_retries`.
- Ensure DLQ queues and `plosolver-dlx` exchange exist (worker declares them on start).

## Testing

### Test Publishing a Job

```python
# Create a job in your application's database first
from core.models import Job, JobType

# Use your application's SQLAlchemy session
# Example (pseudo-code): session = get_app_db_session()

job = Job(
    user_id="test-user-id",
    job_type=JobType.SPOT_SIMULATION,
    input_data={
        "top_board": ["Ah", "Kh", "Qh"],
        "bottom_board": ["2c", "3c", "4c"],
        "players": [
            {"cards": ["As", "Ks", "Qs", "Js"]},
            {"cards": ["2d", "3d", "4d", "5d"]}
        ],
        "simulation_runs": 10000
    }
)
session.add(job)
session.commit()

# Send to Celery
celery.send_task(
    'celery_worker.tasks.process_spot_simulation',
    args=[job.id],
    queue='spot-processing'
)
```

### Check Worker Logs

```bash
# In celery-worker container
tail -f logs/backend.log
```

You should see:
```
[INFO] Starting spot simulation for job <job-id> (task <task-id>)
[INFO] Found job <job-id> with status QUEUED
[INFO] Updated job <job-id> status to PROCESSING
...
[INFO] Spot simulation completed for job <job-id>
```

## Troubleshooting

### "Received and deleted unknown message"

**Cause:** Message format doesn't match Celery protocol

**Fix:** Use `send_task()` instead of manually publishing to RabbitMQ

### Task not found

**Cause:** Task name incorrect

**Fix:** Use full path:
- `celery_worker.tasks.process_spot_simulation`
- `celery_worker.tasks.process_solver_analysis`

### Message goes to DLQ immediately

**Cause:**
1. Task is raising an exception immediately (e.g., job not found)
2. Database connection issues
3. Task logic errors

**Fix:** Check worker logs for the actual error

### Jobs not going to DLQ after failures

**Cause:** Tasks are catching exceptions and returning error responses instead of re-raising them

**Fix:** Ensure tasks raise exceptions after logging errors so Celery can handle retries and DLQ routing properly

### How to Reprocess DLQ Messages

```python
# Move message from DLQ back to main queue
channel.basic_get(queue='spot-processing-dlq', auto_ack=False)
# Manually republish to main queue
celery.send_task('celery_worker.tasks.process_spot_simulation', args=[job_id], queue='spot-processing')
```

## Summary

1. ✅ Backend creates Job in database
2. ✅ Backend uses `celery.send_task()` to publish to RabbitMQ
3. ✅ Celery worker picks up message from `plosolver` exchange
4. ✅ Worker processes job, updates database
5. ✅ On failure, retries 3 times
6. ✅ After 3 failures, message moves to DLQ on `plosolver-dlx` exchange
