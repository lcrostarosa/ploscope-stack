#!/usr/bin/env python3
"""
Multi-language protobuf build script.
Generates Python and Node.js packages from the same proto source files.
"""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


def run_command(cmd, cwd=None, check=True):
    """Run a command and return the result."""
    print(f"Running: {' '.join(cmd)}")
    if cwd:
        print(f"  in directory: {cwd}")

    result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)

    if result.returncode != 0 and check:
        print(f"Error running command: {' '.join(cmd)}")
        print(f"STDOUT: {result.stdout}")
        print(f"STDERR: {result.stderr}")
        sys.exit(1)

    return result


def generate_python_protos():
    """Generate Python protobuf files."""
    print("=== Generating Python protobuf files ===")

    project_root = Path(__file__).parent.parent
    protos_dir = project_root / "protos"
    python_output_dir = project_root / "packages" / "python" / "src" / "plosolver_protos" / "generated"

    # Create output directory
    python_output_dir.mkdir(parents=True, exist_ok=True)

    # Find all .proto files
    proto_files = list(protos_dir.glob("*.proto"))

    if not proto_files:
        print("No .proto files found in protos directory")
        return False

    print(f"Found {len(proto_files)} .proto files")

    # Generate Python files for each .proto file
    for proto_file in proto_files:
        print(f"Generating Python files for {proto_file.name}...")

        cmd = [
            "python",
            "-m",
            "grpc_tools.protoc",
            f"--proto_path={protos_dir}",
            f"--python_out={python_output_dir}",
            f"--grpc_python_out={python_output_dir}",
            str(proto_file),
        ]

        run_command(cmd)
        print(f"Successfully generated Python files for {proto_file.name}")

    # Fix import statements in generated files
    print("Fixing import statements...")
    fix_python_imports(python_output_dir)

    # Create __init__.py file in the generated directory
    init_file = python_output_dir / "__init__.py"
    if not init_file.exists():
        init_file.touch()
        print("Created __init__.py file in generated directory")

    print("Python protobuf generation completed successfully!")
    return True


def fix_python_imports(output_dir):
    """Fix import statements in generated Python files."""
    import re

    # Find all generated Python files
    pb2_files = list(output_dir.glob("*_pb2.py"))
    grpc_files = list(output_dir.glob("*_pb2_grpc.py"))
    py_files = pb2_files + grpc_files

    for py_file in py_files:
        print(f"  Fixing imports in {py_file.name}...")

        # Read the file
        with open(py_file, "r") as f:
            content = f.read()

        # Fix import statements to use relative imports
        lines = content.split("\n")
        fixed_lines = []

        for line in lines:
            # Check if this is an import line for our custom protos
            if line.strip().startswith("import ") and "_pb2" in line and "google.protobuf" not in line:
                # Replace "import common_pb2" with "from . import common_pb2"
                line = re.sub(r"import (\w+_pb2) as (\w+)", r"from . import \1 as \2", line)
            fixed_lines.append(line)

        content = "\n".join(fixed_lines)

        # Write the fixed content back
        with open(py_file, "w") as f:
            f.write(content)


def generate_nodejs_protos():
    """Generate Node.js protobuf files and build the package."""
    print("=== Generating Node.js protobuf files ===")

    project_root = Path(__file__).parent.parent
    nodejs_dir = project_root / "packages" / "nodejs"

    # Install Node.js dependencies if needed
    if not (nodejs_dir / "node_modules").exists():
        print("Installing Node.js dependencies...")
        run_command(["npm", "install"], cwd=nodejs_dir)

    # Build the TypeScript package
    print("Building TypeScript package...")
    run_command(["npm", "run", "build"], cwd=nodejs_dir)

    print("Node.js protobuf generation completed successfully!")
    return True


def build_python_package():
    """Build the Python package."""
    print("=== Building Python package ===")

    project_root = Path(__file__).parent.parent
    python_dir = project_root / "packages" / "python"

    # Build the package
    run_command(["poetry", "build"], cwd=python_dir)

    print("Python package built successfully!")
    return True


def build_nodejs_package():
    """Build the Node.js package."""
    print("=== Building Node.js package ===")

    project_root = Path(__file__).parent.parent
    nodejs_dir = project_root / "packages" / "nodejs"

    # The package is already built by the generate step
    print("Node.js package built successfully!")
    return True


def publish_python_package(dry_run=True):
    """Publish the Python package to PyPI/Nexus."""
    print("=== Publishing Python package ===")

    project_root = Path(__file__).parent.parent
    python_dir = project_root / "packages" / "python"

    if dry_run:
        print("DRY RUN: Would publish Python package to Nexus")
        print("To actually publish, run with --publish flag")
    else:
        # Publish to Nexus
        run_command(["poetry", "publish", "--repository", "nexus-internal"], cwd=python_dir)
        print("Python package published successfully!")

    return True


def publish_nodejs_package(dry_run=True):
    """Publish the Node.js package to NPM."""
    print("=== Publishing Node.js package ===")

    project_root = Path(__file__).parent.parent
    nodejs_dir = project_root / "packages" / "nodejs"

    if dry_run:
        print("DRY RUN: Would publish Node.js package to NPM")
        print("To actually publish, run with --publish flag")
    else:
        # Publish to NPM
        run_command(["npm", "publish"], cwd=nodejs_dir)
        print("Node.js package published successfully!")

    return True


def main():
    """Main build function."""
    import argparse

    parser = argparse.ArgumentParser(description="Build protobuf packages for Python and Node.js")
    parser.add_argument("--python-only", action="store_true", help="Only build Python package")
    parser.add_argument("--nodejs-only", action="store_true", help="Only build Node.js package")
    parser.add_argument("--publish", action="store_true", help="Actually publish packages (default is dry run)")
    parser.add_argument("--skip-build", action="store_true", help="Skip building, only generate protobufs")

    args = parser.parse_args()

    print("Starting multi-language protobuf build...")

    success = True

    try:
        if not args.nodejs_only:
            success &= generate_python_protos()
            if not args.skip_build:
                success &= build_python_package()
                success &= publish_python_package(dry_run=not args.publish)

        if not args.python_only:
            success &= generate_nodejs_protos()
            if not args.skip_build:
                success &= build_nodejs_package()
                success &= publish_nodejs_package(dry_run=not args.publish)

        if success:
            print("\n✅ All builds completed successfully!")
        else:
            print("\n❌ Some builds failed!")
            sys.exit(1)

    except KeyboardInterrupt:
        print("\n⚠️  Build interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Build failed with error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
