## syntax=docker/dockerfile:1.4
FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    rm -f /var/lib/apt/lists/lock /var/cache/apt/archives/lock && \
    mkdir -p /var/cache/apt/archives/partial && \
    apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Set work directory
WORKDIR /app

# Install Python dependencies (minimal for migrations)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /app/migrations/requirements.txt

# Copy migration files from this context into /app/migrations
COPY . /app/migrations

# Set Python path (not required for explicit migrations but harmless)
ENV PYTHONPATH=/app

# Default command - run alembic; supports optional -x schema_user/password passed at runtime
CMD ["alembic", "-c", "/app/migrations/alembic.ini", "upgrade", "head"]