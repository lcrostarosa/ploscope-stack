#!/usr/bin/env python3
"""
Build script for compiling the Celery application with Cython.
This creates native C extensions for better performance.
"""

import os
import subprocess
import sys
from pathlib import Path


def build_cython():
    """Build the Celery application using Cython."""

    # Get the current directory
    current_dir = Path(__file__).parent

    print("Building Cython extensions...")

    try:
        # Build the Cython extensions
        cmd = [sys.executable, "setup.py", "build_ext", "--inplace"]
        print(f"Command: {' '.join(cmd)}")

        result = subprocess.run(cmd, check=True, capture_output=True, text=True, cwd=current_dir)
        print("Cython build successful!")

        # List the generated files
        print("\nGenerated files:")
        for ext_file in current_dir.glob("src/*.so"):
            print(f"  {ext_file}")
        for ext_file in current_dir.glob("src/*.pyd"):
            print(f"  {ext_file}")

        return True

    except subprocess.CalledProcessError as e:
        print(f"Build failed with error: {e}")
        print(f"stdout: {e.stdout}")
        print(f"stderr: {e.stderr}")
        return False


def create_launcher_script():
    """Create a launcher script that imports the compiled extensions."""

    launcher_content = '''#!/usr/bin/env python3
"""
Launcher script for the compiled Cython Celery application.
"""

import os
import sys

# Ensure src is on the path
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

if __name__ == '__main__':
    os.environ.setdefault('PYTHONPATH', 'src')
    from celery_worker.main import main

    main()
'''

    current_dir = Path(__file__).parent
    launcher_path = current_dir / "celery_launcher.py"

    with open(launcher_path, "w") as f:
        f.write(launcher_content)

    # Make it executable
    os.chmod(launcher_path, 0o755)
    print(f"Created launcher script: {launcher_path}")


if __name__ == "__main__":
    success = build_cython()
    if success:
        create_launcher_script()
    sys.exit(0 if success else 1)
