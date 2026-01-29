## syntax=docker/dockerfile:1.4
FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies and Poetry
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    rm -f /var/lib/apt/lists/lock /var/cache/apt/archives/lock && \
    mkdir -p /var/cache/apt/archives/partial && \
    apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/* && \
    curl -sSL https://install.python-poetry.org | python3 -

# Set work directory
WORKDIR /app

# Copy project files
COPY pyproject.toml /app/
COPY alembic.ini /app/
COPY env.py /app/
COPY versions /app/versions

# Configure Poetry and install dependencies
ENV POETRY_HOME="/root/.local/share/pypoetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    PATH="/root/.local/bin:$PATH"

RUN pip install --no-cache-dir --upgrade pip && \
    poetry --version && \
    poetry install --only main --no-root --no-ansi

# Set Python path and ALEMBIC script location for Poetry venv
ENV PYTHONPATH=/app \
    ALEMBIC_CONFIG=/app/alembic.ini

# Default command - run alembic via Poetry
CMD ["poetry", "run", "alembic", "-c", "/app/alembic.ini", "upgrade", "head"]
