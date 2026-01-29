import logging
import os
from datetime import timedelta
from logging.handlers import RotatingFileHandler


class Config:
    """Base configuration class."""

    SECRET_KEY = os.environ.get("SECRET_KEY") or "dev-secret-key"
    JWT_SECRET_KEY = os.environ.get("JWT_SECRET_KEY") or "jwt-secret-key"
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=1)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)

    # Database configuration
    SQLALCHEMY_DATABASE_URI = os.environ.get("DATABASE_URL") or (
        f"postgresql://{os.environ.get('POSTGRES_USER', 'postgres')}:"
        f"{os.environ.get('POSTGRES_PASSWORD', 'postgres')}@"
        f"{os.environ.get('POSTGRES_HOST', 'localhost')}:"
        f"{os.environ.get('POSTGRES_PORT', '5432')}/"
        f"{os.environ.get('POSTGRES_DB', 'plosolver')}"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # SQLAlchemy engine options for better connection management
    SQLALCHEMY_ENGINE_OPTIONS = {
        "pool_pre_ping": True,  # Verify connections before use
        "pool_recycle": 3600,  # Recycle connections after 1 hour
        "pool_timeout": 30,  # Timeout for getting connection
        "pool_size": 10,  # Connection pool size
        "max_overflow": 20,  # Maximum overflow connections
    }

    # File upload configuration
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB max file size
    UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "uploads")
    ALLOWED_EXTENSIONS = {"txt", "csv", "json"}

    # Redis configuration
    REDIS_URL = os.environ.get("REDIS_URL") or "redis://localhost:6379/0"

    # RabbitMQ configuration
    RABBITMQ_URL = os.environ.get("RABBITMQ_URL") or "amqp://guest:guest@localhost:5672/"

    # Celery configuration
    CELERY_BROKER_URL = os.environ.get("CELERY_BROKER_URL") or RABBITMQ_URL
    CELERY_RESULT_BACKEND = os.environ.get("CELERY_RESULT_BACKEND") or REDIS_URL

    # WebSocket configuration
    WEBSOCKET_CORS_ORIGINS = os.environ.get("WEBSOCKET_CORS_ORIGINS", "").split(",") or [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:3001",
        "http://127.0.0.1:3001",
        "http://localhost",
        "http://127.0.0.1",
        "http://*.ngrok-free.app",
        "https://ploscope.com",
        "http://frontend",
    ]

    # Logging configuration
    LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO")
    LOG_FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

    # Security configuration
    CORS_ORIGINS = os.environ.get("CORS_ORIGINS", "").split(",") or [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:3001",
        "http://127.0.0.1:3001",
        "http://localhost",
        "http://127.0.0.1",
        "http://*.ngrok-free.app",
        "https://ploscope.com",
        "http://frontend",
    ]

    # Feature flags
    ENABLE_ANALYTICS = os.environ.get("ENABLE_ANALYTICS", "false").lower() == "true"
    ENABLE_FORUM_INTEGRATION = os.environ.get("ENABLE_FORUM_INTEGRATION", "false").lower() == "true"

    # Credit system configuration
    DEFAULT_CREDITS = int(os.environ.get("DEFAULT_CREDITS", "100"))
    CREDIT_COST_PER_SOLVE = int(os.environ.get("CREDIT_COST_PER_SOLVE", "1"))

    # Session configuration
    SESSION_COOKIE_SECURE = os.environ.get("SESSION_COOKIE_SECURE", "false").lower() == "true"
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = "Lax"

    # Rate limiting
    RATELIMIT_ENABLED = os.environ.get("RATELIMIT_ENABLED", "true").lower() == "true"
    RATELIMIT_STORAGE_URL = os.environ.get("RATELIMIT_STORAGE_URL") or REDIS_URL

    # Email configuration
    MAIL_SERVER = os.environ.get("MAIL_SERVER", "smtp.gmail.com")
    MAIL_PORT = int(os.environ.get("MAIL_PORT", "587"))
    MAIL_USE_TLS = os.environ.get("MAIL_USE_TLS", "true").lower() == "true"
    MAIL_USERNAME = os.environ.get("MAIL_USERNAME")
    MAIL_PASSWORD = os.environ.get("MAIL_PASSWORD")
    MAIL_DEFAULT_SENDER = os.environ.get("MAIL_DEFAULT_SENDER")

    # Stripe configuration
    STRIPE_SECRET_KEY = os.environ.get("STRIPE_SECRET_KEY")
    STRIPE_PUBLISHABLE_KEY = os.environ.get("STRIPE_PUBLISHABLE_KEY")
    STRIPE_WEBHOOK_SECRET = os.environ.get("STRIPE_WEBHOOK_SECRET")

    # Forum integration
    FORUM_API_URL = os.environ.get("FORUM_API_URL")
    FORUM_API_KEY = os.environ.get("FORUM_API_KEY")

    # Analytics configuration
    ANALYTICS_ENDPOINT = os.environ.get("ANALYTICS_ENDPOINT")
    ANALYTICS_API_KEY = os.environ.get("ANALYTICS_API_KEY")

    # Health check configuration
    HEALTH_CHECK_TIMEOUT = int(os.environ.get("HEALTH_CHECK_TIMEOUT", "5"))

    # Job processing configuration
    MAX_CONCURRENT_JOBS = int(os.environ.get("MAX_CONCURRENT_JOBS", "10"))
    JOB_TIMEOUT = int(os.environ.get("JOB_TIMEOUT", "300"))  # 5 minutes

    # File processing configuration
    MAX_FILE_SIZE = int(os.environ.get("MAX_FILE_SIZE", "16777216"))  # 16MB
    ALLOWED_FILE_TYPES = os.environ.get("ALLOWED_FILE_TYPES", "txt,csv,json").split(",")

    # Cache configuration
    CACHE_TYPE = os.environ.get("CACHE_TYPE", "redis")
    CACHE_REDIS_URL = os.environ.get("CACHE_REDIS_URL") or REDIS_URL
    CACHE_DEFAULT_TIMEOUT = int(os.environ.get("CACHE_DEFAULT_TIMEOUT", "300"))

    # Monitoring configuration
    ENABLE_METRICS = os.environ.get("ENABLE_METRICS", "false").lower() == "true"
    METRICS_PORT = int(os.environ.get("METRICS_PORT", "9090"))

    # Signup limiting & waitlist
    SIGNUP_LIMIT = int(os.environ.get("SIGNUP_LIMIT", "10"))
    WAITLIST_NOTIFY_EMAIL = os.environ.get("WAITLIST_NOTIFY_EMAIL")

    # Development configuration
    DEBUG = False
    TESTING = False

    @staticmethod
    def init_app(app):
        """Initialize application configuration."""
        pass


class DevelopmentConfig(Config):
    """Development configuration."""

    DEBUG = True
    SQLALCHEMY_TRACK_MODIFICATIONS = True

    # Development-specific SQLAlchemy options
    SQLALCHEMY_ENGINE_OPTIONS = {
        "pool_pre_ping": True,
        "pool_recycle": 1800,  # Recycle connections after 30 minutes
        "pool_timeout": 20,
        "pool_size": 5,
        "max_overflow": 10,
        "echo": True,  # Log SQL queries
    }


class TestingConfig(Config):
    """Testing configuration."""

    TESTING = True
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = (
        os.environ.get("DATABASE_URL")
        or os.environ.get("TEST_DATABASE_URL")
        or "postgresql://testuser:testpassword@localhost:5432/plosolver"
    )
    WTF_CSRF_ENABLED = False
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(minutes=5)  # Shorter for tests

    # SQLAlchemy engine options for better test environment stability
    SQLALCHEMY_ENGINE_OPTIONS = {
        "pool_pre_ping": True,  # Verify connections before use
        "pool_recycle": 300,  # Recycle connections after 5 minutes
        "pool_timeout": 10,  # Shorter timeout for tests
        "pool_size": 5,  # Smaller pool for tests
        "max_overflow": 5,  # Smaller overflow for tests
        "echo": False,  # Don't log SQL in tests
    }

    # Disable rate limiting in tests
    RATELIMIT_ENABLED = False

    # Use in-memory cache for tests
    CACHE_TYPE = "simple"

    # Disable external routes_grpc in tests
    ENABLE_ANALYTICS = False
    ENABLE_FORUM_INTEGRATION = False


class ProductionConfig(Config):
    """Production configuration."""

    # Production-specific SQLAlchemy options
    SQLALCHEMY_ENGINE_OPTIONS = {
        "pool_pre_ping": True,
        "pool_recycle": 3600,  # Recycle connections after 1 hour
        "pool_timeout": 30,
        "pool_size": 20,  # Larger pool for production
        "max_overflow": 30,  # Larger overflow for production
        "echo": False,  # Don't log SQL in production
    }

    # Security settings for production
    SESSION_COOKIE_SECURE = True
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = "Strict"

    # Enable all features in production
    ENABLE_ANALYTICS = True
    ENABLE_FORUM_INTEGRATION = True

    # Production logging
    LOG_LEVEL = "WARNING"

    @classmethod
    def init_app(cls, app):
        """Initialize production configuration."""
        Config.init_app(app)

        # Production-specific initialization
        # Set up file logging for production
        if not app.debug and not app.testing:
            if not os.path.exists("logs"):
                os.mkdir("logs")
            file_handler = RotatingFileHandler("logs/plosolver.log", maxBytes=10240000, backupCount=10)
            file_handler.setFormatter(
                logging.Formatter("%(asctime)s %(levelname)s: %(message)s " "[in %(pathname)s:%(lineno)d]")
            )
            file_handler.setLevel(logging.INFO)
            app.logger.addHandler(file_handler)

            app.logger.setLevel(logging.INFO)
            app.logger.info("PLOSolver startup")


class StagingConfig(Config):
    """Staging configuration."""

    DEBUG = False
    SQLALCHEMY_TRACK_MODIFICATIONS = True

    # Staging-specific SQLAlchemy options
    SQLALCHEMY_ENGINE_OPTIONS = {
        "pool_pre_ping": True,
        "pool_recycle": 1800,  # Recycle connections after 30 minutes
        "pool_timeout": 20,
        "pool_size": 10,  # Medium pool for staging
        "max_overflow": 15,  # Medium overflow for staging
        "echo": True,  # Log SQL queries in staging
    }

    # Staging logging
    LOG_LEVEL = "INFO"

    # Enable features for testing in staging
    ENABLE_ANALYTICS = True
    ENABLE_FORUM_INTEGRATION = True


# Configuration dictionary
config = {
    "development": DevelopmentConfig,
    "testing": TestingConfig,
    "production": ProductionConfig,
    "staging": StagingConfig,
    "default": DevelopmentConfig,
}
