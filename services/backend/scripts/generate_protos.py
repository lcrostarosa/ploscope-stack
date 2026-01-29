#!/usr/bin/env python3
"""
Script to generate Python protobuf files from .proto definitions.
"""

import subprocess
import sys
from pathlib import Path


def generate_protos():
    """Generate Python protobuf files from .proto definitions."""

    # Get the project root directory
    project_root = Path(__file__).parent.parent
    protos_dir = project_root / "protos"
    output_dir = project_root / "src" / "protos"

    # Create output directory if it doesn't exist
    output_dir.mkdir(parents=True, exist_ok=True)

    # Find all .proto files
    # Find all .proto files in the protos directory, excluding plosolver_main.proto
    proto_files = [f for f in protos_dir.glob("*.proto") if f.name != "plosolver_main.proto"]

    if not proto_files:
        print("No .proto files found in protos directory")
        return False

    print(f"Found {len(proto_files)} .proto files")

    # Generate Python files for each .proto file
    for proto_file in proto_files:
        print(f"Generating Python files for {proto_file.name}...")

        try:
            # Run protoc to generate Python files
            cmd = [
                "python",
                "-m",
                "grpc_tools.protoc",
                f"--proto_path={protos_dir}",
                f"--proto_path={protos_dir.parent}",
                f"--python_out={output_dir}",
                f"--grpc_python_out={output_dir}",
                str(proto_file),
            ]

            result = subprocess.run(cmd, capture_output=True, text=True)

            if result.returncode != 0:
                print(f"Error generating protobuf files for " f"{proto_file.name}:")
                print(result.stderr)
                return False
            else:
                print(f"Successfully generated Python files for " f"{proto_file.name}")

        except Exception as e:
            print(f"Error running protoc for {proto_file.name}: {e}")
            return False

    # Fix import statements in generated files
    print("Fixing import statements...")
    fix_imports(output_dir)

    # Create __init__.py file in the protos directory
    init_file = output_dir / "__init__.py"
    if not init_file.exists():
        init_file.touch()
        print("Created __init__.py file in protos directory")

    print("Protobuf generation completed successfully!")
    return True


def fix_imports(output_dir):
    """Fix import statements in generated files to use relative imports."""
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
        # Only target our custom proto imports, not Google protobuf imports
        # Look for imports that don't start with 'google.protobuf'
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


if __name__ == "__main__":
    success = generate_protos()
    sys.exit(0 if success else 1)
