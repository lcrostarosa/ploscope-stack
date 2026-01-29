import os
from typing import Any, Dict, Optional
from urllib.parse import urlparse

from core.utils.logging_utils import get_enhanced_logger
from sqlalchemy import create_engine
from sqlalchemy import text as sa_text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import scoped_session, sessionmaker

logger = get_enhanced_logger(__name__)


def log_solver_solution(
    *,
    user_id: str,
    name: str,
    game_state: Dict[str, Any],
    solution: Any,
    solve_time: Optional[float] = None,
    description: Optional[str] = None,
) -> Dict[str, Any]:
    """Log solver solution for observability.

    In this worker, we do not persist solver solutions directly. Instead we
    log a structured record so downstream services can capture it from logs, or
    this can be wired to actual persistence later.
    """
    record = {
        "user_id": user_id,
        "name": name,
        "game_state": game_state,
        "solution": solution,
        "solve_time": solve_time,
        "description": description,
    }
    # Structured log for observability. Can be swapped for DB persistence later.
    logger.info("SolverSolution recorded: %s", {k: ("<omitted>" if k == "solution" else v) for k, v in record.items()})
    return record


class Database:
    """Process-wide singleton for SQLAlchemy engine and session factory.

    Provides a single `scoped_session` per process and exposes a simple
    connectivity check. Configuration is sourced from the `DATABASE_URL`
    environment variable.
    """

    _instance: Optional["Database"] = None

    def __init__(self) -> None:
        self._engine: Optional[Engine] = None
        self._session_factory: Optional[Any] = None
        self._scoped_session: Optional[Any] = None

        database_url = os.environ.get(
            "DATABASE_URL",
            "postgresql://postgres:postgres@db:5432/plosolver",
        )

        logger.info("Database URL: %s", database_url)
        if not database_url or database_url == "NOT_SET":
            logger.error("DATABASE_URL environment variable is not set!")
            raise ValueError("DATABASE_URL environment variable is required")

        try:
            parsed = urlparse(database_url)
            logger.info(
                "Parsed URL - scheme: %s, netloc: %s, path: %s",
                parsed.scheme,
                parsed.netloc,
                parsed.path,
            )
            if not parsed.scheme or not parsed.netloc:
                raise ValueError("Invalid URL format: %s" % database_url)
        except Exception as parse_error:
            logger.error("Failed to parse DATABASE_URL: %s", str(parse_error))
            logger.error("Database URL was: %s", database_url)
            raise ValueError("Invalid DATABASE_URL format: %s" % str(parse_error)) from parse_error

        try:
            self._engine = create_engine(
                database_url,
                pool_size=10,
                max_overflow=20,
                pool_recycle=3600,
                pool_pre_ping=True,
                pool_timeout=30,
                echo=False,
            )
            SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self._engine)
            self._session_factory = SessionLocal
            self._scoped_session = scoped_session(SessionLocal)
        except Exception as e:
            logger.error("Failed to create database engine: %s", str(e))
            logger.error("Database URL was: %s", database_url)
            raise

    @classmethod
    def instance(cls) -> "Database":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def get_scoped_session(self):  # returns callable scoped_session
        if self._scoped_session is None:
            raise RuntimeError("Database not initialized")
        return self._scoped_session

    def remove(self) -> None:
        if self._scoped_session is not None:
            self._scoped_session.remove()

    def test_connection(self) -> None:
        """Open a connection and run a simple query. Raises on failure."""
        if self._engine is None:
            raise RuntimeError("Database engine not initialized")
        with self._engine.connect() as conn:
            conn.execute(sa_text("SELECT 1"))


def get_db_session():
    """Return process-wide scoped_session from the database singleton.

    This function provides access to the database session factory.
    and also for `tasks.get_db_session` to delegate to.
    """
    return Database.instance().get_scoped_session()


def check_database_connection() -> None:
    """Test database connectivity and raise on failure."""
    try:
        Database.instance().test_connection()
        logger.info("Database connection test successful")
    except Exception as e:
        logger.error("Database connection test failed: %s", str(e))
        raise


def _reset_database_singleton_for_tests() -> None:
    """Reset the singleton instance. Intended for use in unit tests only."""
    Database._instance = None
