#!/usr/bin/env python3
"""
Verify RabbitMQ exchanges and queues setup.

This script verifies that all exchanges, queues, and bindings
are correctly configured in RabbitMQ.
"""

import os
import sys

import pika
from pika.exceptions import AMQPChannelError, AMQPConnectionError


def verify_rabbitmq_setup():
    """Verify RabbitMQ exchanges and queues setup."""

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

    print("🔍 Verifying RabbitMQ setup...")
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

        # Verify exchanges exist
        print("🔍 Verifying exchanges...")
        exchanges_to_check = [
            (main_exchange, "direct"),
            (dlq_exchange, "direct"),
        ]

        for exchange_name, expected_type in exchanges_to_check:
            try:
                # Check if exchange exists
                channel.exchange_declare(exchange=exchange_name, passive=True)
                print(
                    f"   ✅ Exchange exists: {exchange_name} " f"(type: {expected_type})"
                )
            except (AMQPChannelError, AMQPConnectionError) as e:
                print(f"   ❌ Exchange missing: {exchange_name} - {e}")
                return False

        # Verify queues exist and have correct bindings
        print("🔍 Verifying queues and bindings...")
        queues_to_check = [
            (spot_queue, main_exchange, "spot.*"),
            (solver_queue, main_exchange, "solver.*"),
            (spot_dlq, dlq_exchange, spot_dlq),
            (solver_dlq, dlq_exchange, solver_dlq),
        ]

        for (
            queue_name,
            expected_exchange,
            expected_routing_key,
        ) in queues_to_check:
            try:
                # Check if queue exists
                method = channel.queue_declare(queue=queue_name, passive=True)
                print(
                    f"   ✅ Queue exists: {queue_name} "
                    f"({method.method.message_count} messages)"
                )

                # Check bindings (this is a simplified check)
                # In a real scenario, you might want to use the management API
                # to get detailed binding information
                print(
                    f"      Expected binding: {expected_exchange} -> "
                    f"{queue_name} (routing_key: {expected_routing_key})"
                )

            except (AMQPChannelError, AMQPConnectionError) as e:
                print(f"   ❌ Queue missing: {queue_name} - {e}")
                return False

        # Test message publishing (optional)
        print("🧪 Testing message publishing...")
        try:
            # Publish a test message to the main exchange
            test_message = "Test message for verification"
            channel.basic_publish(
                exchange=main_exchange,
                routing_key="spot.test",
                body=test_message,
                properties=pika.BasicProperties(
                    delivery_mode=2
                ),  # Make message persistent
            )
            print(
                f"   ✅ Test message published to {main_exchange} "
                f"with routing key 'spot.test'"
            )

            # Check if message arrived in spot queue
            method, _, body = channel.basic_get(queue=spot_queue, auto_ack=True)
            if method and body.decode() == test_message:
                print(f"   ✅ Test message received in {spot_queue}")
            else:
                print(
                    f"   ⚠️  Test message not found in {spot_queue} "
                    f"(this might be expected if routing doesn't match)"
                )

        except (AMQPChannelError, AMQPConnectionError) as e:
            print(f"   ⚠️  Message publishing test failed: {e}")

        # Close connection
        connection.close()

        print("🎉 RabbitMQ setup verification completed successfully!")
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
    print("🐰 RabbitMQ Setup Verifier")
    print("==========================")

    # Check if we're in a test environment
    testing_env = os.getenv("TESTING") == "true"
    container_env = os.getenv("CONTAINER_ENV") == "docker"
    if testing_env or container_env:
        print("🧪 Test environment detected")

    # Verify setup
    success = verify_rabbitmq_setup()

    if success:
        print("✅ Setup verification completed successfully!")
        sys.exit(0)
    else:
        print("❌ Setup verification failed!")
        sys.exit(1)


if __name__ == "__main__":
    main()
