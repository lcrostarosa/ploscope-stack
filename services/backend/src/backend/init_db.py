"""
Database initialization script for PLOSolver Backend.

This script creates all database tables and initializes the database.
"""

import os
import sys
from pathlib import Path

# Add the backend directory to the Python path
backend_path = Path(__file__).parent
sys.path.insert(0, str(backend_path))

parent_path = backend_path.parent
sys.path.insert(0, str(parent_path))

from flask import Flask

from config import config
from src.backend.database import db

# Models are imported by the database initialization


def init_database():
    """Initialize the database with all tables."""
    # Create Flask app
    app = Flask(__name__)

    # Get configuration based on environment
    config_name = os.getenv("FLASK_ENV", "development")
    app.config.from_object(config[config_name])

    # Initialize the database
    db.init_app(app)

    with app.app_context():
        print("🔧 Creating database tables...")
        db.create_all()
        print("✅ Database tables created successfully!")

        # Print table information
        inspector = db.inspect(db.engine)
        tables = inspector.get_table_names()
        print(f"📋 Created tables: {', '.join(tables)}")


if __name__ == "__main__":
    init_database()
