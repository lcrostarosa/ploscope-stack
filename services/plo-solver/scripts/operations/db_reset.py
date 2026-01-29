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
    from flask_migrate import Migrate, stamp

    # Create minimal Flask app for database operations only
    from flask import Flask

    def create_db_app():
        """Create minimal Flask app for database operations only"""
        app = Flask(__name__)
        app.config.from_object(DevelopmentConfig)
        db.init_app(app)
        migrate = Migrate(app, db, directory=str(backend_path / "migrations"))
        return app, migrate

    try:
        print("🔧 Creating database app...")
        app, migrate = create_db_app()
        
        with app.app_context():
            print("🗑️  Dropping all tables...")
            db.drop_all()
            print("✅ All tables dropped")
            
            print("🔄 Recreating tables...")
            db.create_all()
            print("✅ Tables recreated")
            
            print("🏷️  Stamping migration head...")
            stamp()
            print("✅ Migration head stamped")
            
            print("✅ Database reset completed successfully!")
            
    except Exception as e:
        print("❌ Database reset failed: " + str(e))
        sys.exit(1)

if __name__ == "__main__":
    main() 