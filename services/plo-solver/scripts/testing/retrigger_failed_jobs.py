#!/usr/bin/env python3
"""
Script to retrigger failed jobs from RabbitMQ dead letter queues.

This script allows operators to:
1. List failed jobs in DLQs
2. Retrigger specific failed jobs
3. Retrigger all failed jobs
4. Clear failed jobs from DLQs

Usage:
    python retrigger_failed_jobs.py --list
    python retrigger_failed_jobs.py --retrigger-all
    python retrigger_failed_jobs.py --retrigger-job <job_id>
    python retrigger_failed_jobs.py --clear-all
"""

import os
import sys
import json
import argparse
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime

# Add the backend directory to the Python path
backend_path = os.path.join(os.path.dirname(__file__), '..', '..', 'src', 'backend')
if backend_path not in sys.path:
    sys.path.insert(0, backend_path)

try:
    import pika
    from pika.exceptions import AMQPConnectionError, AMQPChannelError
except ImportError:
    print("❌ pika library not available. Install with: pip install pika")
    sys.exit(1)

from services.celery_service import get_celery_app
from plosolver_core.models.job import Job
from plosolver_core.models.enums import JobStatus
from plosolver_core.models.base import db
from utils.logging_utils import get_enhanced_logger

logger = get_enhanced_logger(__name__)


class DLQManager:
    """Manages dead letter queue operations for failed jobs."""
    
    def __init__(self):
        """Initialize DLQ manager with RabbitMQ connection."""
        self.host = os.getenv("RABBITMQ_HOST", "localhost")
        self.port = int(os.getenv("RABBITMQ_PORT", "5672"))
        self.username = os.getenv("RABBITMQ_USERNAME", "guest")
        self.password = os.getenv("RABBITMQ_PASSWORD", "guest")
        self.vhost = os.getenv("RABBITMQ_VHOST", "/")
        
        # Queue names
        self.spot_dlq = os.getenv("RABBITMQ_SPOT_DLQ", "spot-processing-dlq")
        self.solver_dlq = os.getenv("RABBITMQ_SOLVER_DLQ", "solver-processing-dlq")
        
        # Database connection
        self.database_url = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@db:5432/plosolver")
        
        # Celery app
        self.celery_app = get_celery_app()
        
        self.connection = None
        self.channel = None
    
    def connect(self):
        """Establish connection to RabbitMQ."""
        try:
            credentials = pika.PlainCredentials(self.username, self.password)
            parameters = pika.ConnectionParameters(
                host=self.host,
                port=self.port,
                virtual_host=self.vhost,
                credentials=credentials,
                heartbeat=600,
                blocked_connection_timeout=300,
            )
            
            self.connection = pika.BlockingConnection(parameters)
            self.channel = self.connection.channel()
            logger.info("✅ Connected to RabbitMQ successfully")
            return True
            
        except AMQPConnectionError as e:
            logger.error(f"❌ Failed to connect to RabbitMQ: {e}")
            return False
        except Exception as e:
            logger.error(f"❌ Unexpected error connecting to RabbitMQ: {e}")
            return False
    
    def disconnect(self):
        """Close RabbitMQ connection."""
        if self.connection and not self.connection.is_closed:
            self.connection.close()
            logger.info("🔌 Disconnected from RabbitMQ")
    
    def get_dlq_message_count(self, queue_name: str) -> int:
        """Get the number of messages in a DLQ."""
        try:
            method = self.channel.queue_declare(queue=queue_name, passive=True)
            return method.method.message_count
        except Exception as e:
            logger.error(f"Failed to get message count for {queue_name}: {e}")
            return 0
    
    def list_failed_jobs(self) -> Dict[str, List[Dict[str, Any]]]:
        """List all failed jobs in DLQs."""
        failed_jobs = {
            'spot_simulation': [],
            'solver_analysis': []
        }
        
        # Check spot simulation DLQ
        spot_count = self.get_dlq_message_count(self.spot_dlq)
        if spot_count > 0:
            logger.info(f"📋 Found {spot_count} failed spot simulation jobs")
            failed_jobs['spot_simulation'] = self._get_dlq_messages(self.spot_dlq, spot_count)
        
        # Check solver analysis DLQ
        solver_count = self.get_dlq_message_count(self.solver_dlq)
        if solver_count > 0:
            logger.info(f"📋 Found {solver_count} failed solver analysis jobs")
            failed_jobs['solver_analysis'] = self._get_dlq_messages(self.solver_dlq, solver_count)
        
        return failed_jobs
    
    def _get_dlq_messages(self, queue_name: str, count: int) -> List[Dict[str, Any]]:
        """Get messages from a DLQ without consuming them."""
        messages = []
        
        try:
            # Get messages without consuming them
            for _ in range(min(count, 100)):  # Limit to 100 messages for safety
                method_frame, properties, body = self.channel.basic_get(queue=queue_name, auto_ack=False)
                
                if method_frame:
                    try:
                        # Parse message body
                        message_data = json.loads(body.decode('utf-8'))
                        job_id = message_data.get('job_id') if isinstance(message_data, dict) else None
                        
                        messages.append({
                            'job_id': job_id,
                            'queue': queue_name,
                            'delivery_tag': method_frame.delivery_tag,
                            'body': message_data,
                            'properties': {
                                'headers': properties.headers if properties.headers else {},
                                'timestamp': properties.timestamp,
                                'message_id': properties.message_id,
                            }
                        })
                        
                        # Reject the message to put it back in the queue
                        self.channel.basic_nack(method_frame.delivery_tag, requeue=True)
                        
                    except json.JSONDecodeError:
                        logger.warning(f"Failed to parse message in {queue_name}")
                        self.channel.basic_nack(method_frame.delivery_tag, requeue=True)
                    except Exception as e:
                        logger.error(f"Error processing message in {queue_name}: {e}")
                        self.channel.basic_nack(method_frame.delivery_tag, requeue=True)
                else:
                    break
                    
        except Exception as e:
            logger.error(f"Error getting messages from {queue_name}: {e}")
        
        return messages
    
    def retrigger_job(self, job_id: str) -> bool:
        """Retrigger a specific failed job."""
        try:
            # Find the job in the database
            job = Job.query.filter_by(id=job_id).first()
            if not job:
                logger.error(f"❌ Job {job_id} not found in database")
                return False
            
            # Check if job is in a failed state
            if job.status not in [JobStatus.FAILED, JobStatus.CANCELLED]:
                logger.warning(f"⚠️ Job {job_id} is not in a failed state (status: {job.status.value})")
            
            # Reset job status
            job.status = JobStatus.QUEUED
            job.started_at = None
            job.completed_at = None
            job.error_message = None
            job.progress_percentage = 0
            job.progress_message = "Job requeued for processing"
            
            # Submit to Celery based on job type
            task_id = None
            if job.job_type.value == "SPOT_SIMULATION":
                task_id = self.celery_app.send_task('main.tasks.process_spot_simulation', args=[job_id])
            elif job.job_type.value == "SOLVER_ANALYSIS":
                task_id = self.celery_app.send_task('main.tasks.process_solver_analysis', args=[job_id])
            else:
                logger.error(f"❌ Unsupported job type: {job.job_type.value}")
                return False
            
            if task_id:
                job.queue_message_id = task_id.id
                db.session.commit()
                logger.info(f"✅ Successfully retriggered job {job_id} with task ID {task_id.id}")
                return True
            else:
                logger.error(f"❌ Failed to submit job {job_id} to Celery")
                db.session.rollback()
                return False
                
        except Exception as e:
            logger.error(f"❌ Error retriggering job {job_id}: {e}")
            db.session.rollback()
            return False
    
    def retrigger_all_failed_jobs(self) -> Dict[str, int]:
        """Retrigger all failed jobs from DLQs."""
        results = {'success': 0, 'failed': 0}
        
        # Get all failed jobs
        failed_jobs = self.list_failed_jobs()
        
        for job_type, jobs in failed_jobs.items():
            logger.info(f"🔄 Retriggering {len(jobs)} failed {job_type} jobs...")
            
            for job_info in jobs:
                job_id = job_info.get('job_id')
                if job_id:
                    if self.retrigger_job(job_id):
                        results['success'] += 1
                    else:
                        results['failed'] += 1
                else:
                    logger.warning(f"⚠️ Skipping job without job_id: {job_info}")
                    results['failed'] += 1
        
        return results
    
    def clear_dlq(self, queue_name: str) -> int:
        """Clear all messages from a DLQ."""
        try:
            # Purge the queue
            method = self.channel.queue_purge(queue=queue_name)
            logger.info(f"🗑️ Cleared {method} messages from {queue_name}")
            return method
        except Exception as e:
            logger.error(f"❌ Error clearing DLQ {queue_name}: {e}")
            return 0
    
    def clear_all_dlqs(self) -> Dict[str, int]:
        """Clear all DLQs."""
        results = {}
        
        # Clear spot simulation DLQ
        spot_count = self.clear_dlq(self.spot_dlq)
        results['spot_simulation'] = spot_count
        
        # Clear solver analysis DLQ
        solver_count = self.clear_dlq(self.solver_dlq)
        results['solver_analysis'] = solver_count
        
        return results


def main():
    """Main function to handle command line arguments."""
    parser = argparse.ArgumentParser(description="Manage failed jobs in RabbitMQ DLQs")
    parser.add_argument("--list", action="store_true", help="List all failed jobs in DLQs")
    parser.add_argument("--retrigger-all", action="store_true", help="Retrigger all failed jobs")
    parser.add_argument("--retrigger-job", type=str, help="Retrigger a specific job by ID")
    parser.add_argument("--clear-all", action="store_true", help="Clear all DLQs (DANGEROUS)")
    parser.add_argument("--verbose", "-v", action="store_true", help="Enable verbose logging")
    
    args = parser.parse_args()
    
    # Setup logging
    log_level = logging.DEBUG if args.verbose else logging.INFO
    logging.basicConfig(
        level=log_level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # Initialize DLQ manager
    dlq_manager = DLQManager()
    
    if not dlq_manager.connect():
        logger.error("❌ Failed to connect to RabbitMQ. Exiting.")
        sys.exit(1)
    
    try:
        if args.list:
            print("\n📋 Failed Jobs in DLQs:")
            print("=" * 50)
            
            failed_jobs = dlq_manager.list_failed_jobs()
            
            if not any(failed_jobs.values()):
                print("✅ No failed jobs found in DLQs")
            else:
                for job_type, jobs in failed_jobs.items():
                    if jobs:
                        print(f"\n🔴 {job_type.upper()} ({len(jobs)} jobs):")
                        for job in jobs:
                            job_id = job.get('job_id', 'Unknown')
                            print(f"   - Job ID: {job_id}")
                            if job.get('properties', {}).get('timestamp'):
                                timestamp = datetime.fromtimestamp(job['properties']['timestamp'])
                                print(f"     Timestamp: {timestamp}")
        
        elif args.retrigger_all:
            print("\n🔄 Retriggering all failed jobs...")
            results = dlq_manager.retrigger_all_failed_jobs()
            print(f"\n📊 Results:")
            print(f"   ✅ Successfully retriggered: {results['success']}")
            print(f"   ❌ Failed to retrigger: {results['failed']}")
        
        elif args.retrigger_job:
            print(f"\n🔄 Retriggering job {args.retrigger_job}...")
            if dlq_manager.retrigger_job(args.retrigger_job):
                print(f"✅ Successfully retriggered job {args.retrigger_job}")
            else:
                print(f"❌ Failed to retrigger job {args.retrigger_job}")
                sys.exit(1)
        
        elif args.clear_all:
            print("\n⚠️ WARNING: This will permanently delete all failed jobs from DLQs!")
            confirm = input("Are you sure you want to continue? (yes/no): ")
            
            if confirm.lower() == 'yes':
                print("\n🗑️ Clearing all DLQs...")
                results = dlq_manager.clear_all_dlqs()
                print(f"\n📊 Results:")
                for queue, count in results.items():
                    print(f"   {queue}: {count} messages cleared")
            else:
                print("❌ Operation cancelled")
        
        else:
            parser.print_help()
    
    finally:
        dlq_manager.disconnect()


if __name__ == "__main__":
    main() 