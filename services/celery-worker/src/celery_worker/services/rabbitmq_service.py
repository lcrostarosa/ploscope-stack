import os
import urllib


def get_broker_url():
    broker_url = os.environ.get("CELERY_BROKER_URL")

    if not broker_url:
        rabbit_user = os.environ.get("RABBITMQ_DEFAULT_USER", os.environ.get("RABBITMQ_USERNAME", "plosolver"))
        rabbit_pass = os.environ.get(
            "RABBITMQ_DEFAULT_PASS",
            os.environ.get("RABBITMQ_PASSWORD", "dev_password_2024"),
        )
        rabbit_host = os.environ.get("RABBITMQ_HOST", "rabbitmq")
        rabbit_port = os.environ.get("RABBITMQ_PORT", "5672")
        rabbit_vhost = os.environ.get("RABBITMQ_DEFAULT_VHOST", os.environ.get("RABBITMQ_VHOST", "/plosolver"))

        # For AMQP URLs, vhosts with leading slash need to be URL-encoded
        # When vhost starts with '/', we need to URL-encode the entire vhost name
        if rabbit_vhost.startswith("/"):
            vhost_enc = urllib.parse.quote(rabbit_vhost, safe="")
        else:
            vhost_enc = urllib.parse.quote(rabbit_vhost)
        return f"amqp://{rabbit_user}:{rabbit_pass}@{rabbit_host}:{rabbit_port}/{vhost_enc}"

    return broker_url
