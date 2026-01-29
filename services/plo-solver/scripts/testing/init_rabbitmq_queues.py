#!/usr/bin/env python3
"""
Initialize RabbitMQ queues for testing.

This script creates the required queues (spot-processing, solver-processing)
and their corresponding dead letter queues for the test environment.
"""

import os
import sys
import json
import time
from typing import Dict, Any

# Add the backend directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../src/backend'))

try:
    import pika
    from pika.exceptions import AMQPConnectionError, AMQPChannelError
except ImportError:
    print("❌ Error: pika is not installed. Install with: pip install pika")
    sys.exit(1)


def init_rabbitmq_queues():
    """Initialize RabbitMQ queues for testing."""
    
    # Get RabbitMQ connection parameters from environment
    host = os.getenv("RABBITMQ_HOST", "localhost")
    port = int(os.getenv("RABBITMQ_PORT", "5672"))
    username = os.getenv("RABBITMQ_USERNAME", "plosolver")
    password = os.getenv("RABBITMQ_PASSWORD", "dev_password_2024")
    vhost = os.getenv("RABBITMQ_VHOST", "/plosolver")
    
    # Queue names
    spot_queue = os.getenv("RABBITMQ_SPOT_QUEUE", "spot-processing")
    solver_queue = os.getenv("RABBITMQ_SOLVER_QUEUE", "solver-processing")
    spot_dlq = os.getenv("RABBITMQ_SPOT_DLQ", "spot-processing-dlq")
    solver_dlq = os.getenv("RABBITMQ_SOLVER_DLQ", "solver-processing-dlq")
    
    print(f"🔧 Initializing RabbitMQ queues...")
    print(f"   Host: {host}:{port}")
    print(f"   VHost: {vhost}")
    print(f"   User: {username}")
    
    try:
        # Create connection parameters
        credentials = pika.PlainCredentials(username, password)
        parameters = pika.ConnectionParameters(
            host=host,
            port=port,
            virtual_host=vhost,
            credentials=credentials,
            heartbeat=600,
            blocked_connection_timeout=300,
        )
        
        # Connect to RabbitMQ
        print("📡 Connecting to RabbitMQ...")
        connection = pika.BlockingConnection(parameters)
        channel = connection.channel()
        
        print("✅ Connected to RabbitMQ successfully!")
        
        # Declare dead letter queues first
        print("📋 Declaring dead letter queues...")
        
        # Spot processing DLQ
        channel.queue_declare(
            queue=spot_dlq,
            durable=True,
            arguments={
                "x-message-ttl": 1209600000,  # 14 days in milliseconds
            },
        )
        print(f"   ✅ Created DLQ: {spot_dlq}")
        
        # Solver processing DLQ
        channel.queue_declare(
            queue=solver_dlq,
            durable=True,
            arguments={
                "x-message-ttl": 1209600000,  # 14 days in milliseconds
            },
        )
        print(f"   ✅ Created DLQ: {solver_dlq}")
        
        # Declare main queues with DLQ configuration
        print("📋 Declaring main queues...")
        
        # Spot processing queue
        channel.queue_declare(
            queue=spot_queue,
            durable=True,
            arguments={
                "x-dead-letter-exchange": "",
                "x-dead-letter-routing-key": spot_dlq,
                "x-max-retries": 3,
            },
        )
        print(f"   ✅ Created queue: {spot_queue}")
        
        # Solver processing queue
        channel.queue_declare(
            queue=solver_queue,
            durable=True,
            arguments={
                "x-dead-letter-exchange": "",
                "x-dead-letter-routing-key": solver_dlq,
                "x-max-retries": 3,
            },
        )
        print(f"   ✅ Created queue: {solver_queue}")
        
        # Verify queues exist
        print("🔍 Verifying queue creation...")
        
        # Get queue info to verify they exist
        for queue_name in [spot_queue, solver_queue, spot_dlq, solver_dlq]:
            try:
                method = channel.queue_declare(queue=queue_name, passive=True)
                print(f"   ✅ Verified queue: {queue_name} ({method.method.message_count} messages)")
            except Exception as e:
                print(f"   ❌ Failed to verify queue {queue_name}: {e}")
                return False
        
        # Close connection
        connection.close()
        
        print("🎉 RabbitMQ queues initialized successfully!")
        return True
        
    except AMQPConnectionError as e:
        print(f"❌ Failed to connect to RabbitMQ: {e}")
        print("   Make sure RabbitMQ is running and accessible")
        return False
    except AMQPChannelError as e:
        print(f"❌ RabbitMQ channel error: {e}")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False


def main():
    """Main function."""
    print("🐰 RabbitMQ Queue Initializer")
    print("=============================")
    
    # Check if we're in a test environment
    if os.getenv("TESTING") == "true" or os.getenv("CONTAINER_ENV") == "docker":
        print("🧪 Test environment detected")
    
    # Initialize queues
    success = init_rabbitmq_queues()
    
    if success:
        print("✅ Queue initialization completed successfully!")
        sys.exit(0)
    else:
        print("❌ Queue initialization failed!")
        sys.exit(1)


if __name__ == "__main__":
    main() 