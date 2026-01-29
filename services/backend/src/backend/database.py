"""
Database configuration and initialization for PLOSolver Backend.

This module provides SQLAlchemy database setup and initialization.
"""

from flask_bcrypt import Bcrypt
from flask_sqlalchemy import SQLAlchemy

# Initialize Flask extensions
db = SQLAlchemy()
bcrypt = Bcrypt()
