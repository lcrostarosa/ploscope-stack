#!/usr/bin/env python3
"""
Build script for creating a binary version of the Celery application.
This script handles the complex PyInstaller configuration needed for Celery.
"""

import subprocess
import sys
from pathlib import Path


def build_binary():
    """Build the Celery application binary using PyInstaller."""

    # Get the current directory
    current_dir = Path(__file__).parent
    src_dir = current_dir / "src"

    # PyInstaller command with all necessary options for Celery
    cmd = [
        "pyinstaller",
        "--onefile",  # Create a single executable
        "--distpath",
        str(current_dir / "dist"),  # Output directory
        "--workpath",
        str(current_dir / "build"),  # Build directory
        "--specpath",
        str(current_dir),  # Spec file directory
        "--name",
        "celery_app",  # Binary name
        # Add data files
        "--add-data",
        f"{src_dir}:src",
        # Hidden imports for Celery
        "--hidden-import",
        "celery",
        "--hidden-import",
        "celery.app",
        "--hidden-import",
        "celery.worker",
        "--hidden-import",
        "celery.bin.celery",
        "--hidden-import",
        "celery.bin.worker",
        "--hidden-import",
        "src.celery_app",
        "--hidden-import",
        "src.tasks",
        "--hidden-import",
        "src.celery_app.celery",
        # Additional hidden imports that might be needed
        "--hidden-import",
        "kombu",
        "--hidden-import",
        "billiard",
        "--hidden-import",
        "amqp",
        "--hidden-import",
        "pika",
        # Exclude unnecessary modules to reduce size
        "--exclude-module",
        "matplotlib",
        "--exclude-module",
        "numpy",
        "--exclude-module",
        "pandas",
        "--exclude-module",
        "scipy",
        "--exclude-module",
        "PIL",
        "--exclude-module",
        "tkinter",
        "--exclude-module",
        "PyQt5",
        "--exclude-module",
        "PySide2",
        # The main script to build
        str(src_dir / "celery_app.py"),
    ]

    print("Building binary with PyInstaller...")
    print(f"Command: {' '.join(cmd)}")

    try:
        print("Build successful!")
        print(f"Binary created at: {current_dir / 'dist' / 'celery_app'}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Build failed with error: {e}")
        print(f"stdout: {e.stdout}")
        print(f"stderr: {e.stderr}")
        return False


if __name__ == "__main__":
    success = build_binary()
    sys.exit(0 if success else 1)
