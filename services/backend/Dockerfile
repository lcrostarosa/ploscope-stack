# Multi-stage build for backend - OPTIMIZED with Poetry
FROM python:3.11.9-slim AS builder

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
    pipx \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry via pipx and ensure Poetry is available on PATH
RUN pipx install poetry
ENV PATH="/root/.local/bin:$PATH"

# Copy Poetry configuration files
COPY pyproject.toml poetry.lock* poetry.toml* ./

# Allow overriding Poetry options via build args (used by docker compose build)
ARG BUILD_ENV=production

# Configure Poetry to use Nexus repositories
RUN --mount=type=secret,id=nexus_username \
    --mount=type=secret,id=nexus_password \
    set -e; \
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


# Production stage
FROM python:3.11.9-slim AS production

# Accept the BUILD_ENV argument in the production stage as well
ARG BUILD_ENV=production

WORKDIR /app/backend
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_INPUT=1

# Install only runtime system dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    rm -f /var/lib/apt/lists/lock /var/cache/apt/archives/lock && \
    mkdir -p /var/cache/apt/archives/partial && \
    apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    curl \
    netcat-traditional \
    libgomp1 \
    libstdc++6 \
    libgcc-s1 \
    && rm -rf /var/lib/apt/lists/*

# Copy virtual environment from builder stage
COPY --from=builder /app/.venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Create non-root user for production
RUN groupadd -g 1000 appuser && \
    useradd -m -s /bin/bash -u 1000 -g appuser appuser && \
    chown -R appuser:appuser /opt/venv

# Copy application source
COPY src/ ./src/
COPY config.py ./

# Migrations are managed by a dedicated db-init image; backend image does not include them

# Create necessary directories and set permissions
RUN mkdir -p /app/uploads && \
    mkdir -p /app/logs && \
    chown -R appuser:appuser /app && \
    chmod -R 755 /app && \
    chmod -R 777 /app/uploads && \
    chmod -R 777 /app/logs

# Switch to non-root user
USER appuser

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5001/api/health || exit 1

EXPOSE 5001
EXPOSE 50051

# Run Flask under Gunicorn with Eventlet workers via Python module runner
# This avoids shebang path issues in console scripts after venv relocation
ENV WORKERS=1
ENV WORKER_CLASS=eventlet
ENV BIND=0.0.0.0:5001
ENV WSGI_APP=src.backend.main:create_flask_app()

CMD ["python", "-m", "gunicorn", "-k", "eventlet", "-w", "1", "-b", "0.0.0.0:5001", "src.backend.main:create_flask_app()"]
