#!/usr/bin/env python3

import sys
import os
from pathlib import Path

def main():
    # Add backend to path - script is run from project root
    backend_path = Path.cwd() / "src" / "backend"
    sys.path.insert(0, str(backend_path))

    # Import only what we need for database operations
    from config import DevelopmentConfig
    from plosolver_core.models.base import db
    from sqlalchemy import text

    # Create minimal Flask app for database operations only
    from flask import Flask

    def create_db_app():
        """Create minimal Flask app for database operations only"""
        app = Flask(__name__)
        app.config.from_object(DevelopmentConfig)
        db.init_app(app)
        return app

    try:
        app = create_db_app()
        with app.app_context():
            # Test basic connection
            result = db.session.execute(text("SELECT 1"))
            print("CONNECTED")
            
            # Get database URL info
            db_url = app.config.get("SQLALCHEMY_DATABASE_URI", "Unknown")
            print("DB_URL:" + db_url)
            
            # Simple table count
            result = db.session.execute(text("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'"))
            total_tables = result.scalar()
            print("TOTAL_TABLES:" + str(total_tables))
            
            # Check for alembic_version table
            try:
                result = db.session.execute(text("SELECT 1 FROM alembic_version LIMIT 1"))
                print("ALEMBIC:True")
            except:
                print("ALEMBIC:False")
            
            print("SUCCESS")
            
    except Exception as e:
        print("ERROR:" + str(e))
        sys.exit(1)

if __name__ == "__main__":
    main() 