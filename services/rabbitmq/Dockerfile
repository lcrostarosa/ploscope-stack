FROM python:3.11-alpine

WORKDIR /app

# Install system dependencies
RUN apk add --no-cache \
    gcc \
    g++ \
    musl-dev \
    libffi-dev \
    openssl-dev \
    curl

# Install Poetry
ENV PATH="/root/.local/bin:$PATH" \
    POETRY_VIRTUALENVS_CREATE=false
RUN curl -sSL https://install.python-poetry.org | python3 - --yes

# Copy Poetry project files first to leverage Docker layer caching
COPY pyproject.toml poetry.lock* /app/

# Install Python dependencies with Poetry (no virtualenv inside container)
RUN poetry install --no-root --only main --no-interaction --no-ansi

# Copy the RabbitMQ initialization script
COPY init_rabbitmq_queues.py /app/

# Set the working directory
WORKDIR /app

# Run the initialization script
CMD ["python", "init_rabbitmq_queues.py"]
