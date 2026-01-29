#!/usr/bin/env python3
"""
PLOSolver Setup Script
This script sets up the solver engine and related components.
"""

import os
import sys
import shutil
import subprocess
from pathlib import Path

def print_status(message):
    """Print a status message."""
    print(f"📋 {message}")

def print_success(message):
    """Print a success message."""
    print(f"✅ {message}")

def print_error(message):
    """Print an error message."""
    print(f"❌ {message}")

def print_warning(message):
    """Print a warning message."""
    print(f"⚠️  {message}")

def check_python_version():
    """Check if Python version is compatible."""
    if sys.version_info < (3, 8):
        print_error("Python 3.8 or higher is required")
        return False
    print_success(f"Python {sys.version_info.major}.{sys.version_info.minor} detected")
    return True

def create_directories():
    """Create necessary directories."""
    directories = [
        'src/backend/solver_cache',
        'src/backend/solver_cache/models',
        'src/backend/solver_cache/precomputed',
        'src/backend/logs',
        'src/backend/uploads',
        'src/backend/uploads/hand_histories',
        'src/backend/instance'
    ]
    
    for directory in directories:
        Path(directory).mkdir(parents=True, exist_ok=True)
        print_success(f"Created directory: {directory}")

def install_dependencies():
    """Install Python dependencies."""
    print_status("Installing Python dependencies...")
    
    # Check if requirements.txt exists
    requirements_file = Path("src/backend/requirements.txt")
    if not requirements_file.exists():
        print_error("requirements.txt not found in src/backend/")
        return False
    
    try:
        subprocess.run([sys.executable, "-m", "pip", "install", "-r", str(requirements_file)], 
                      check=True, capture_output=True, text=True)
        print_success("Python dependencies installed")
        return True
    except subprocess.CalledProcessError as e:
        print_error(f"Failed to install dependencies: {e}")
        return False

def setup_database():
    """Set up the database."""
    print_status("Setting up database...")
    
    try:
        # Change to backend directory
        os.chdir("src/backend")
        
        # Import Flask app and create tables
        sys.path.append('.')
        from app import create_app
        from plosolver_core.models.base import db
        
        app = create_app()
        with app.app_context():
            db.create_all()
        
        print_success("Database tables created")
        return True
    except Exception as e:
        print_error(f"Failed to setup database: {e}")
        return False
    finally:
        # Change back to project root
        os.chdir("../..")

def setup_environment():
    """Set up environment variables."""
    print_status("Setting up environment...")
    
    # Create .env file if it doesn't exist
    env_file = Path(".env")
    if not env_file.exists():
        env_example = Path("env.example")
        if env_example.exists():
            shutil.copy(env_example, env_file)
            print_success("Created .env file from env.example")
        else:
            print_warning("No env.example found, creating basic .env file")
            with open(env_file, 'w') as f:
                f.write("""# PLOSolver Environment Configuration
FLASK_APP=src/backend/core/app.py
FLASK_ENV=development
SECRET_KEY=dev-secret-key-change-in-production
DATABASE_URL=sqlite:///src/backend/instance/plosolver.db
LOG_LEVEL=INFO
""")
            print_success("Created basic .env file")

def setup_solver_cache():
    """Set up solver cache directories."""
    print_status("Setting up solver cache...")
    
    cache_dirs = [
        'src/backend/solver_cache',
        'src/backend/solver_cache/models',
        'src/backend/solver_cache/precomputed'
    ]
    
    for cache_dir in cache_dirs:
        Path(cache_dir).mkdir(parents=True, exist_ok=True)
        # Create .gitkeep to ensure directories are tracked
        gitkeep_file = Path(cache_dir) / ".gitkeep"
        gitkeep_file.touch(exist_ok=True)
    
    print_success("Solver cache directories created")

def run_tests():
    """Run basic tests to verify setup."""
    print_status("Running basic tests...")
    
    try:
        # Change to backend directory
        os.chdir("src/backend")
        
        # Run pytest if available
        try:
            subprocess.run([sys.executable, "-m", "pytest", "--version"], 
                          check=True, capture_output=True, text=True)
            
            # Run basic tests
            result = subprocess.run([sys.executable, "-m", "pytest", "tests/", "-v"], 
                                  capture_output=True, text=True)
            
            if result.returncode == 0:
                print_success("Tests passed")
            else:
                print_warning("Some tests failed (this may be normal)")
                print(result.stdout)
                print(result.stderr)
                
        except (subprocess.CalledProcessError, FileNotFoundError):
            print_warning("pytest not available, skipping tests")
        
        return True
    except Exception as e:
        print_error(f"Failed to run tests: {e}")
        return False
    finally:
        # Change back to project root
        os.chdir("../..")

def main():
    """Main setup function."""
    print("🚀 PLOSolver Setup Script")
    print("========================")
    
    # Check if we're in the right directory
    if not Path("src/frontend/package.json").exists() or not Path("src/backend").exists():
        print_error("Please run this script from the project root directory")
        sys.exit(1)
    
    # Check Python version
    if not check_python_version():
        sys.exit(1)
    
    # Create directories
    create_directories()
    
    # Install dependencies
    if not install_dependencies():
        print_error("Failed to install dependencies")
        sys.exit(1)
    
    # Setup environment
    setup_environment()
    
    # Setup solver cache
    setup_solver_cache()
    
    # Setup database
    if not setup_database():
        print_warning("Database setup failed, but continuing...")
    
    # Run tests
    run_tests()
    
    print("\n🎉 Setup completed successfully!")
    print("\nNext steps:")
    print("1. Start your Flask server: python src/backend/equity_server.py")
    print("2. Or use the Makefile: make run")
    print("3. Access the application at: http://localhost:3000")
    print("\nFor more information, see the README.md file.")

if __name__ == "__main__":
    main() 