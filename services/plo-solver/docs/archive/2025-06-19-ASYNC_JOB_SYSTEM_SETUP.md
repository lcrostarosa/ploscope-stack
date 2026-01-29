# Async Job Processing System Setup

This document describes how to set up and use the new asynchronous job processing system for PLOSolver, which uses AWS SQS for job queuing and implements a credit-based usage system.

## Overview

The async job system allows users to submit computationally intensive tasks (spot simulations and solver analysis) that are processed in the background. Users receive immediate feedback that their job has been queued, and can monitor progress in real-time.

### Key Features

- **Asynchronous Processing**: Jobs are queued and processed by background workers
- **Credit System**: Usage limits based on subscription tiers
- **Real-time Progress**: Live updates on job status and progress
- **Time Estimates**: Estimated completion times based on job complexity
- **Queue Management**: Separate queues for different job types
- **Fault Tolerance**: Dead letter queues and retry mechanisms

## Infrastructure Setup

### 1. AWS Infrastructure with Terraform

The system requires AWS SQS queues and IAM roles. Use the provided Terraform configuration:

```bash
# Initialize Terraform for development
cd terraform
terraform init -backend-config=environments/dev/backend.hcl

# Plan the deployment
terraform plan -var-file=environments/dev/terraform.tfvars

# Apply the infrastructure
terraform apply -var-file=environments/dev/terraform.tfvars
```

**Required AWS Resources:**
- SQS queues for spot processing and solver analysis
- Dead letter queues for failed messages
- IAM roles and policies for queue access
- CloudWatch log groups for monitoring
- CloudWatch alarms for queue depth monitoring

### 2. Environment Variables

Add these environment variables to your application:

```env
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key

# SQS Queue URLs (from Terraform outputs)
SPOT_PROCESSING_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/123456789/plosolver-dev-spot-processing
SOLVER_PROCESSING_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/123456789/plosolver-dev-solver-processing

# Worker Configuration
SPOT_WORKER_COUNT=2
SOLVER_WORKER_COUNT=1
WORKER_POLL_INTERVAL=10
```

### 3. Database Migration

Run the database migration to create the new tables:

```bash
cd backend
flask db upgrade
```

This creates:
- `jobs` table for tracking job status
- `user_credits` table for managing usage limits
- Associated indexes for performance

## Credit System

### Subscription Tiers and Limits

| Tier | Daily Limit | Monthly Limit |
|------|-------------|---------------|
| Free | 1 job | 30 jobs |
| Pro | 10 jobs | 100 jobs |
| Elite | 20 jobs | 500 jobs |

### Credit Management

Credits are automatically managed:
- Credits reset daily and monthly
- Limits are enforced before job submission
- Failed job submissions don't consume credits

## API Endpoints

### Job Management

- `POST /api/jobs/submit` - Submit a new job
- `GET /api/jobs` - Get user's jobs with pagination
- `GET /api/jobs/{id}` - Get specific job details
- `POST /api/jobs/{id}/cancel` - Cancel a queued job
- `GET /api/jobs/credits` - Get credit information
- `GET /api/jobs/recent` - Get recent and active jobs

### Async Processing

- `POST /spots/simulate` - Submit spot simulation
- `POST /solver/solutions/analyze` - Submit solver analysis

## Job Worker Setup

### Running the Worker

The job worker processes queued jobs:

```bash
cd backend
python job_worker.py
```

### Worker Configuration

Configure workers via environment variables:
- `SPOT_WORKER_COUNT`: Number of spot simulation workers (default: 2)
- `SOLVER_WORKER_COUNT`: Number of solver analysis workers (default: 1)
- `WORKER_POLL_INTERVAL`: Polling interval in seconds (default: 10)

### Production Deployment

For production, run workers as services:

```yaml
# docker compose.yml
services:
  job-worker:
    build: .
    command: python job_worker.py
    environment:
      - AWS_REGION=us-east-1
      - SPOT_PROCESSING_QUEUE_URL=${SPOT_PROCESSING_QUEUE_URL}
      - SOLVER_PROCESSING_QUEUE_URL=${SOLVER_PROCESSING_QUEUE_URL}
    restart: unless-stopped
```

## Frontend Integration

### JobStatusPanel Component

Add the job status panel to your React components:

```jsx
import JobStatusPanel from './components/jobs/JobStatusPanel';

function Dashboard() {
    return (
        <div>
            <JobStatusPanel onJobCompleted={(job) => {
                // Handle job completion
                console.log('Job completed:', job);
            }} />
            {/* Other components */}
        </div>
    );
}
```

### Using Async API Endpoints

Submit jobs using the new async endpoints:

```javascript
// Submit spot simulation
const submitSpotSimulation = async (spotData) => {
    try {
        const response = await api.post('/spots/simulate', spotData);
        return response.data.job; // Returns job object with ID and status
    } catch (error) {
        if (error.response?.status === 429) {
            // Handle insufficient credits
            console.log('Credits exhausted:', error.response.data.credits_info);
        }
        throw error;
    }
};

// Monitor job progress
const monitorJob = async (jobId) => {
    const response = await api.get(`/api/jobs/${jobId}`);
    return response.data.job;
};
```

## Monitoring and Observability

### CloudWatch Metrics

Monitor queue health:
- `ApproximateNumberOfVisibleMessages`: Jobs waiting to be processed
- `ApproximateNumberOfMessagesNotVisible`: Jobs currently being processed

### Application Logs

Workers log to:
- Console output (stdout)
- `/var/log/plosolver/job_worker.log` (configurable)

### Queue Statistics

Elite users and admins can access queue statistics:

```javascript
const getQueueStats = async () => {
    const response = await api.get('/api/jobs/queue-stats');
    return response.data.queue_stats;
};
```

## CI/CD Integration

### GitHub Actions Workflow

The Terraform infrastructure is automatically deployed via GitHub Actions:

1. **Pull Request**: Terraform plan is generated and commented on PR
2. **Merge to Master**: Infrastructure is automatically applied

### Required Secrets

Configure these GitHub secrets:
- `AWS_ROLE_ARN`: IAM role for GitHub Actions
- Any environment-specific variables

## Error Handling and Resilience

### Dead Letter Queues

Failed jobs are automatically moved to dead letter queues after 3 retry attempts.

### Job Cancellation

Users can cancel queued jobs. Processing jobs cannot be cancelled but will complete gracefully.

### Worker Resilience

Workers handle:
- Database connection failures
- SQS service interruptions
- Job processing errors
- Graceful shutdown on SIGTERM/SIGINT

## Development and Testing

### Local Development

For local development without AWS:
1. Mock SQS responses in `sqs_service.py`
2. Use in-memory processing for immediate results
3. Set `SQS_ENABLED=false` to disable queue integration

### Testing

Run tests with:

```bash
cd backend
pytest tests/ -v
```

Tests use `moto` library to mock AWS services.

## Security Considerations

### IAM Permissions

The application uses minimal IAM permissions:
- `sqs:SendMessage`
- `sqs:ReceiveMessage`
- `sqs:DeleteMessage`
- `sqs:GetQueueAttributes`
- `sqs:GetQueueUrl`

### Data Protection

- Job input/output data is stored in the database
- Sensitive information should be excluded from job data
- Queue messages contain only job references, not full data

### Rate Limiting

Built-in rate limiting via credit system prevents abuse and manages costs.

## Cost Optimization

### SQS Costs

- Standard queues: $0.40 per million requests
- Long polling reduces empty receives
- Message retention: 14 days (configurable)

### Worker Scaling

- Scale workers based on queue depth
- Use CloudWatch alarms for auto-scaling
- Consider spot instances for cost savings

## Troubleshooting

### Common Issues

1. **Jobs stuck in queue**: Check worker logs and AWS credentials
2. **Credit issues**: Verify subscription tier and reset dates
3. **Database errors**: Check database connectivity and migrations
4. **AWS connectivity**: Verify IAM roles and network access

### Debug Commands

```bash
# Check queue status
aws sqs get-queue-attributes --queue-url $SPOT_PROCESSING_QUEUE_URL --attribute-names All

# Monitor worker logs
tail -f /var/log/plosolver/job_worker.log

# Check database jobs
psql -c "SELECT id, status, created_at FROM jobs ORDER BY created_at DESC LIMIT 10;"
```

## Migration from Synchronous Processing

### Backend Changes

1. Update existing simulation endpoints to use async processing
2. Maintain backward compatibility with sync endpoints
3. Gradually migrate users to async workflow

### Frontend Changes

1. Add job status monitoring components
2. Update user workflows to handle async results
3. Provide clear feedback on job submission

This async job system provides a scalable foundation for processing intensive computations while maintaining excellent user experience through real-time progress updates and fair usage policies. 