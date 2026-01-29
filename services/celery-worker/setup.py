#!/usr/bin/env python3
"""
Setup script for building the Celery application with Cython.
This creates a native binary from Python source code.
"""

import numpy as np
from Cython.Build import cythonize
from setuptools import Extension, setup

# Define the extensions to compile
extensions = [
    Extension(
        "src.celery_app",
        ["src/celery_app.pyx"],
        include_dirs=[np.get_include()],
        extra_compile_args=["-O3", "-march=native"],
        extra_link_args=["-O3"],
    ),
    Extension(
        "src.tasks",
        ["src/tasks.pyx"],
        include_dirs=[np.get_include()],
        extra_compile_args=["-O3", "-march=native"],
        extra_link_args=["-O3"],
    ),
]

setup(
    name="celery-app",
    version="1.0.0",
    description="Celery application with Cython optimization",
    author="PLOSolver Team",
    ext_modules=cythonize(
        extensions,
        compiler_directives={
            "language_level": 3,
            "boundscheck": False,
            "wraparound": False,
            "initializedcheck": False,
            "nonecheck": False,
            "cdivision": True,
        },
    ),
    zip_safe=False,
    install_requires=[
        "celery",
        "kombu",
        "billiard",
    ],
)
