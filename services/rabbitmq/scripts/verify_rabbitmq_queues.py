#!/usr/bin/env python3
"""
Script to verify RabbitMQ queues exist and are accessible.
Used in CI/CD pipeline to ensure queue initialization was successful.
"""

import argparse
import sys

import pika


def verify_rabbitmq_queues(username, password, host, port, virtual_host, queues):
    """Verify that all expected RabbitMQ queues exist and are accessible."""
    try:
        # Connection parameters
        credentials = pika.PlainCredentials(username, password)
        connection_params = pika.ConnectionParameters(
            host=host,
            port=port,
            virtual_host=virtual_host,
            credentials=credentials,
        )

        # Establish connection
        connection = pika.BlockingConnection(connection_params)
        channel = connection.channel()

        # Verify each queue exists by declaring it passively
        for queue in queues:
            try:
                channel.queue_declare(queue=queue, passive=True)
                print(f"✅ Queue '{queue}' verified successfully")
            except pika.exceptions.ChannelClosedByBroker as e:
                print(f"❌ Queue '{queue}' not found: {e}")
                connection.close()
                sys.exit(1)

        # Close connection
        connection.close()
        print("✅ All RabbitMQ queues verified successfully!")

    except pika.exceptions.AMQPConnectionError as e:
        print(f"❌ Failed to connect to RabbitMQ: {e}")
        sys.exit(1)
    except pika.exceptions.AMQPError as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)


def main():
    """Main function to parse arguments and run verification."""
    parser = argparse.ArgumentParser(
        description="Verify RabbitMQ queues exist and are accessible"
    )
    parser.add_argument("--username", default="test_user", help="RabbitMQ username")
    parser.add_argument("--password", default="test_password", help="RabbitMQ password")
    parser.add_argument("--host", default="db", help="RabbitMQ host")
    parser.add_argument("--port", type=int, default=5673, help="RabbitMQ port")
    parser.add_argument(
        "--virtual-host",
        default="/plosolver",
        help="RabbitMQ virtual host",
    )
    parser.add_argument(
        "--queues",
        nargs="+",
        default=[
            "test-spot-processing",
            "test-solver-processing",
            "test-spot-processing-dlq",
            "test-solver-processing-dlq",
        ],
        help="List of queues to verify",
    )

    args = parser.parse_args()

    verify_rabbitmq_queues(
        username=args.username,
        password=args.password,
        host=args.host,
        port=args.port,
        virtual_host=args.virtual_host,
        queues=args.queues,
    )


if __name__ == "__main__":
    main()
