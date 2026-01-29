#!/usr/bin/env python3
"""
Initialize RabbitMQ exchanges and queues for testing.

This script creates the required exchanges (plosolver.main, plosolver.dlq),
queues (spot-processing, solver-processing), and their corresponding
dead letter queues for the test environment.
"""

import os
import sys

import pika
from pika.exceptions import AMQPChannelError, AMQPConnectionError


def init_rabbitmq_queues():
    """Initialize RabbitMQ exchanges and queues for testing."""

    # Get RabbitMQ connection parameters from environment
    # Strip whitespace to prevent issues
    host = os.getenv("RABBITMQ_HOST", "localhost").strip()
    port = int(os.getenv("RABBITMQ_PORT", "5672").strip())
    username = os.getenv("RABBITMQ_USERNAME", "plosolver").strip()
    password = os.getenv("RABBITMQ_PASSWORD", "dev_password_2024").strip()
    vhost = os.getenv("RABBITMQ_VHOST", "/plosolver").strip()

    # Exchange names - strip whitespace to prevent issues
    main_exchange = os.getenv("RABBITMQ_MAIN_EXCHANGE", "plosolver.main").strip()
    dlq_exchange = os.getenv("RABBITMQ_DLQ_EXCHANGE", "plosolver.dlq").strip()

    # Queue names - strip whitespace to prevent carriage return issues
    spot_queue = os.getenv("RABBITMQ_SPOT_QUEUE", "spot-processing").strip()
    solver_queue = os.getenv("RABBITMQ_SOLVER_QUEUE", "solver-processing").strip()
    spot_dlq = os.getenv("RABBITMQ_SPOT_DLQ", "spot-processing-dlq").strip()
    solver_dlq = os.getenv("RABBITMQ_SOLVER_DLQ", "solver-processing-dlq").strip()

    print("🔧 Initializing RabbitMQ exchanges and queues...")
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

        # Declare exchanges first
        print("📋 Declaring exchanges...")

        # Main exchange (direct type for simple routing)
        channel.exchange_declare(
            exchange=main_exchange,
            exchange_type="direct",
            durable=True,
        )
        print(f"   ✅ Created main exchange: {main_exchange}")

        # Dead letter exchange (direct type for simple routing)
        channel.exchange_declare(
            exchange=dlq_exchange,
            exchange_type="direct",
            durable=True,
        )
        print(f"   ✅ Created DLQ exchange: {dlq_exchange}")

        # Delete existing queues to avoid configuration conflicts
        print("🗑️  Cleaning up existing queues to avoid " "configuration conflicts...")

        queues_to_cleanup = [spot_queue, solver_queue, spot_dlq, solver_dlq]
        for queue_name in queues_to_cleanup:
            try:
                # Try to delete the queue (this will fail silently if it doesn't exist)
                channel.queue_delete(queue=queue_name)
                print(f"   🗑️  Deleted existing queue: {queue_name}")
            except (AMQPChannelError, AMQPConnectionError):
                # Queue doesn't exist, which is fine
                pass

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
        # Bind DLQ to DLQ exchange
        channel.queue_bind(
            exchange=dlq_exchange,
            queue=spot_dlq,
            routing_key=spot_dlq,
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
        # Bind DLQ to DLQ exchange
        channel.queue_bind(
            exchange=dlq_exchange,
            queue=solver_dlq,
            routing_key=solver_dlq,
        )
        print(f"   ✅ Created DLQ: {solver_dlq}")

        # Declare main queues with DLQ configuration
        print("📋 Declaring main queues...")

        # Spot processing queue
        channel.queue_declare(
            queue=spot_queue,
            durable=True,
            arguments={
                "x-dead-letter-exchange": dlq_exchange,
                "x-dead-letter-routing-key": spot_dlq,
                "x-max-retries": 3,
            },
        )
        print(f"   ✅ Created queue: {spot_queue} with DLX: {dlq_exchange}")
        # Bind queue to main exchange
        channel.queue_bind(
            exchange=main_exchange,
            queue=spot_queue,
            routing_key="spot.*",
        )
        print(f"   ✅ Created queue: {spot_queue}")

        # Solver processing queue
        channel.queue_declare(
            queue=solver_queue,
            durable=True,
            arguments={
                "x-dead-letter-exchange": dlq_exchange,
                "x-dead-letter-routing-key": solver_dlq,
                "x-max-retries": 3,
            },
        )
        print(f"   ✅ Created queue: {solver_queue} with DLX: {dlq_exchange}")
        # Bind queue to main exchange
        channel.queue_bind(
            exchange=main_exchange,
            queue=solver_queue,
            routing_key="solver.*",
        )
        print(f"   ✅ Created queue: {solver_queue}")

        # Verify exchanges and queues exist
        print("🔍 Verifying exchange and queue creation...")

        # Verify exchanges exist
        for exchange_name in [main_exchange, dlq_exchange]:
            try:
                channel.exchange_declare(exchange=exchange_name, passive=True)
                print(f"✅ Verified exchange: {exchange_name}")
            except (AMQPChannelError, AMQPConnectionError) as e:
                print(f"❌ Failed to verify exchange {exchange_name}: {e}")
                return False

        # Get queue info to verify they exist
        for queue_name in [spot_queue, solver_queue, spot_dlq, solver_dlq]:
            try:
                method = channel.queue_declare(queue=queue_name, passive=True)
                print(
                    f"✅ Verified queue: {queue_name} "
                    f"({method.method.message_count} messages)"
                )
            except (AMQPChannelError, AMQPConnectionError) as e:
                print(f"❌ Failed to verify queue {queue_name}: {e}")
                return False

        # Close connection
        connection.close()

        print("🎉 RabbitMQ exchanges and queues initialized successfully!")
        return True

    except AMQPConnectionError as e:
        print(f"❌ Failed to connect to RabbitMQ: {e}")
        print("   Make sure RabbitMQ is running and accessible")
        return False
    except AMQPChannelError as e:
        print(f"❌ RabbitMQ channel error: {e}")
        return False


def main():
    """Main function."""
    print("🐰 RabbitMQ Queue Initializer")
    print("=============================")

    # Check if we're in a test environment
    testing_env = os.getenv("TESTING") == "true"
    container_env = os.getenv("CONTAINER_ENV") == "docker"
    if testing_env or container_env:
        print("🧪 Test environment detected")

    # Initialize exchanges and queues
    success = init_rabbitmq_queues()

    if success:
        print("✅ Exchange and queue initialization completed successfully!")
        sys.exit(0)
    else:
        print("❌ Exchange and queue initialization failed!")
        sys.exit(1)


if __name__ == "__main__":
    main()
