# Multi-stage build for celery-worker - OPTIMIZED with Poetry
# syntax=docker/dockerfile:1.6
FROM python:3.11-slim AS builder

WORKDIR /app
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_INPUT=1

# Install build dependencies in a single layer
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    rm -f /var/lib/apt/lists/lock /var/cache/apt/archives/lock && \
    mkdir -p /var/cache/apt/archives/partial && \
    apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libffi-dev \
    libssl-dev \
    libpq-dev \
    gfortran \
    libopenblas-dev \
    liblapack-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
ENV PATH="/root/.local/bin:$PATH"
RUN curl -sSL https://install.python-poetry.org | python3 - && \
    poetry --version

# Copy Poetry configuration files
COPY pyproject.toml poetry.lock* poetry.toml* ./

# Allow overriding Poetry options via build args (used by docker compose build)
ARG BUILD_ENV=production
ARG PIP_INDEX_URL
ARG PIP_TRUSTED_HOST
ARG NEXUS_PYPI_USERNAME
ARG NEXUS_PYPI_PASSWORD

# Propagate PIP env for underlying installers (used by Poetry/pip)
ENV PIP_INDEX_URL=${PIP_INDEX_URL}
ENV PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST}

RUN --mount=type=secret,id=nexus_username \
    --mount=type=secret,id=nexus_password \
    set -e; \
    NEXUS_USER="${NEXUS_PYPI_USERNAME}"; \
    NEXUS_PASS="${NEXUS_PYPI_PASSWORD}"; \
    if [ -f /run/secrets/nexus_username ]; then NEXUS_USER="$(cat /run/secrets/nexus_username)"; fi; \
    if [ -f /run/secrets/nexus_password ]; then NEXUS_PASS="$(cat /run/secrets/nexus_password)"; fi; \
    poetry config virtualenvs.create true; \
    poetry config virtualenvs.in-project true; \
    INDEX_URL="${PIP_INDEX_URL:-https://nexus.ploscope.com/repository/pypi-internal/simple}"; \
    if [ -n "$NEXUS_USER" ] && [ -n "$NEXUS_PASS" ]; then \
        echo "Configuring Poetry to use Nexus at ${INDEX_URL}..."; \
        poetry config repositories.nexus-internal "$INDEX_URL"; \
        poetry config http-basic.nexus-internal "$NEXUS_USER" "$NEXUS_PASS"; \
    else \
        echo "No Nexus credentials provided; exiting"; \
        exit 1; \
    fi; \
    poetry install --only main --no-interaction --no-root --no-cache;


FROM python:3.11-slim AS production

ARG BUILD_ENV=production

WORKDIR /app/
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_INPUT=1
ENV PYTHONPATH="/app/src:/app:${PYTHONPATH}"

# Install only runtime system dependencies
RUN apt update && apt install -y --no-install-recommends \
    postgresql-client \
    curl \
    netcat-traditional \
    libgomp1 \
    libstdc++6 \
    libgcc-s1

# Copy in-project virtualenv from builder and set PATH
ENV VENV=/app/.venv
COPY --from=builder /app/.venv /app/.venv
ENV PATH="$VENV/bin:$PATH"

# Create non-root user for production
RUN groupadd -g 1000 appuser && \
    useradd -m -s /bin/bash -u 1000 -g appuser appuser

RUN mkdir -p /app/logs && \
    chown -R appuser:appuser /app && \
    chmod -R 755 /app && \
    chmod -R 777 /app/logs

USER appuser

COPY pyproject.toml poetry.lock* poetry.toml* /app/

COPY src ./src

COPY --chown=appuser:appuser health_check.py /app/health_check.py
RUN chmod +x /app/health_check.py
# Use module entrypoint for celery worker
CMD ["python", "-m", "celery_worker.main"]
