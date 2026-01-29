#!/usr/bin/env python3
"""
Poetry-compatible build script for Cython extensions.
This script compiles the Cython source files into optimized C extensions.
"""

import sys
from pathlib import Path

import numpy as np
from Cython.Build import cythonize
from setuptools import Extension, setup


def get_numpy_include():
    """Get numpy include directory."""
    try:
        return np.get_include()
    except ImportError:
        # Fallback if numpy is not installed
        return []


def build_extensions():
    """Build Cython extensions with optimization flags."""
    extensions = [
        Extension(
            "src.main.celery_app",
            ["src/main/celery_app.pyx"],
            include_dirs=[get_numpy_include()],
            extra_compile_args=["-O3", "-march=native"],
            extra_link_args=["-O3"],
        ),
        Extension(
            "src.main.tasks",
            ["src/main/tasks.pyx"],
            include_dirs=[get_numpy_include()],
            extra_compile_args=["-O3", "-march=native"],
            extra_link_args=["-O3"],
        ),
    ]

    return cythonize(
        extensions,
        compiler_directives={
            "language_level": 3,
            "boundscheck": False,
            "wraparound": False,
            "initializedcheck": False,
            "nonecheck": False,
            "cdivision": True,
        },
    )


def main():
    """Main build function."""
    print("Building Cython extensions for celery-worker...")

    # Ensure source directory exists
    src_dir = Path("src/main")
    if not src_dir.exists():
        print(f"Error: Source directory {src_dir} does not exist")
        sys.exit(1)

    # Check for Cython source files
    cython_files = list(src_dir.glob("*.pyx"))
    if not cython_files:
        print("Warning: No .pyx files found in src/main/")
        return

    print(f"Found Cython files: {[f.name for f in cython_files]}")

    # Build extensions
    ext_modules = build_extensions()

    # Setup configuration
    setup(
        name="celery-worker-extensions",
        version="1.0.0",
        description="Cython extensions for celery-worker",
        ext_modules=ext_modules,
        zip_safe=False,
    )

    print("✅ Cython extensions built successfully!")


if __name__ == "__main__":
    main()
