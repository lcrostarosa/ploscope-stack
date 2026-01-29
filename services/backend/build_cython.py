#!/usr/bin/env python3
"""
Build script for compiling the backend with Cython.
"""
import subprocess

# import os
import sys
from pathlib import Path


def build_cython():
    current_dir = Path(__file__).parent
    print("Building backend Cython extensions...")
    try:
        cmd = [sys.executable, "setup.py", "build_ext", "--inplace"]
        print(f"Command: {' '.join(cmd)}")
        subprocess.run(cmd, check=True, capture_output=True, text=True, cwd=current_dir)
        print("Cython build successful!")
        print("\nGenerated files:")
        for ext_file in current_dir.glob("core/*.so"):
            print(f"  {ext_file}")
        for ext_file in current_dir.glob("routes_grpc/*.so"):
            print(f"  {ext_file}")
        for ext_file in current_dir.glob("utils/*.so"):
            print(f"  {ext_file}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Build failed with error: {e}")
        print(f"stdout: {e.stdout}")
        print(f"stderr: {e.stderr}")
        return False


if __name__ == "__main__":
    success = build_cython()
    sys.exit(0 if success else 1)
