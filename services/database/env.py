import logging
import os
from logging.config import fileConfig

from alembic import context
from sqlalchemy import engine_from_config, pool

# this is the Alembic Config object, which provides access to the values within the .ini file in use.
config = context.config

# Interpret the config file for Python logging.
fileConfig(config.config_file_name)
logger = logging.getLogger("alembic.env")

# We run explicit, hand-written migrations; autogenerate is not required here.
# Leave target_metadata as None to avoid importing backend application code.
target_metadata = None

# Build sqlalchemy.url from environment, allowing override of schema user/password
database_url = os.environ.get("DATABASE_URL")

# Accept overrides from Alembic -x arguments first, then env vars
try:
    xargs = context.get_x_argument(as_dictionary=True)
except Exception:
    xargs = {}

if database_url:
    # Use DATABASE_URL as-is without schema credential override
    pass
else:
    # Construct URL from individual POSTGRES_* env vars
    host = xargs.get("host") or os.environ.get("POSTGRES_MIGRATE_HOST") or os.environ.get("POSTGRES_HOST", "localhost")
    port = xargs.get("port") or os.environ.get("POSTGRES_PORT", "5432")
    dbname = xargs.get("db") or os.environ.get("POSTGRES_DB", "plosolver")
    user = os.environ.get("POSTGRES_USER", "postgres")
    password = os.environ.get("PGPASSWORD") or os.environ.get("POSTGRES_PASSWORD", "")
    database_url = f"postgresql://{user}:{password}@{host}:{port}/{dbname}"

if not database_url:
    raise RuntimeError("DATABASE_URL must be provided or derivable from POSTGRES_* variables.")

config.set_main_option("sqlalchemy.url", database_url)


def run_migrations_offline():
    """Run migrations in 'offline' mode."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online():
    """Run migrations in 'online' mode."""
    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
