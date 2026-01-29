"""
Documentation routes_http for serving API documentation and generating docs.
"""

import datetime

# import os
import json
import re
import subprocess
import sys
from pathlib import Path

from flask import Blueprint, abort, jsonify, render_template_string, send_from_directory  # current_app,
from werkzeug.exceptions import NotFound

docs_bp = Blueprint("docs", __name__)

# Get the project root directory
PROJECT_ROOT = Path(__file__).parent.parent
DOCS_DIR = PROJECT_ROOT / "docs"
PUBLIC_DOCS_DIR = PROJECT_ROOT / "public" / "docs"


@docs_bp.route("/")
def docs_index():
    """Serve the main documentation index page."""
    try:
        # Try to serve from public/docs first, then fallback to docs/
        for docs_path in [PUBLIC_DOCS_DIR, DOCS_DIR]:
            index_file = docs_path / "index.html"
            if index_file.exists():
                with open(index_file, "r") as f:
                    return f.read()

        # If no index file exists, return a simple page with links
        return render_template_string(
            """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PLOSolver Documentation</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 40px;
            background: #f8f9fa;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background: white;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
        }
        .error {
            color: #e53e3e;
            margin-bottom: 20px;
        }
        .action-btn {
            display: inline-block;
            background: #4299e1;
            color: white;
            padding: 12px 24px;
            text-decoration: none;
            border-radius: 6px;
            margin: 10px;
            transition: background 0.2s;
        }
        .action-btn:hover {
            background: #3182ce;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📚 PLOSolver Documentation</h1>
        <div class="error">
            <strong>Documentation not found!</strong>
            <p>The documentation hasn't been generated yet.</p>
        </div>
        <p>Click the button below to generate the documentation:</p>
        <a href="/docs/generate" class="action-btn">🚀 Generate Documentation</a>
        <br>
        <p><small>Or run: <code>python scripts/docs/generate_docs.py</code></small></p>
    </div>
</body>
</html>
        """
        )

    except Exception as e:
        return jsonify({"error": f"Failed to serve documentation index: {str(e)}"}), 500


@docs_bp.route("/openapi.json")
def serve_openapi_spec():
    """Serve the OpenAPI specification JSON."""
    try:
        # Try to find the OpenAPI spec file
        for docs_path in [PUBLIC_DOCS_DIR, DOCS_DIR]:
            openapi_file = docs_path / "openapi.json"
            if openapi_file.exists():
                with open(openapi_file, "r") as f:
                    return jsonify(json.load(f))

        return (
            jsonify({"error": "OpenAPI specification not found. Please generate documentation first."}),
            404,
        )

    except Exception as e:
        return jsonify({"error": f"Failed to serve OpenAPI spec: {str(e)}"}), 500


@docs_bp.route("/react-components.json")
def serve_react_docs():
    """Serve the React components documentation JSON."""
    try:
        # Try to find the React docs file
        for docs_path in [PUBLIC_DOCS_DIR, DOCS_DIR]:
            react_file = docs_path / "react-components.json"
            if react_file.exists():
                with open(react_file, "r") as f:
                    return jsonify(json.load(f))

        return (
            jsonify({"error": "React components documentation not found. Please generate documentation first."}),
            404,
        )

    except Exception as e:
        return jsonify({"error": f"Failed to serve React documentation: {str(e)}"}), 500


@docs_bp.route("/react-components.html")
def serve_react_html():
    """Serve the React components HTML documentation."""
    try:
        # Try to find the React HTML file
        for docs_path in [PUBLIC_DOCS_DIR, DOCS_DIR]:
            react_file = docs_path / "react-components.html"
            if react_file.exists():
                with open(react_file, "r") as f:
                    return f.read()

        return (
            "<h1>React documentation not found</h1><p>Please generate documentation first.</p>",
            404,
        )

    except Exception as e:
        return (
            f"<h1>Error</h1><p>Failed to serve React documentation: {str(e)}</p>",
            500,
        )


@docs_bp.route("/api-docs.md")
def serve_api_markdown():
    """Serve the API documentation in Markdown format."""
    try:
        # Try to find the API markdown file
        for docs_path in [PUBLIC_DOCS_DIR, DOCS_DIR]:
            md_file = docs_path / "api_docs.md"
            if md_file.exists():
                with open(md_file, "r") as f:
                    content = f.read()
                # Simple markdown to HTML conversion for display
                content = re.sub(r"^# (.+)$", r"<h1>\1</h1>", content, flags=re.MULTILINE)
                content = re.sub(r"^## (.+)$", r"<h2>\1</h2>", content, flags=re.MULTILINE)
                content = re.sub(r"^### (.+)$", r"<h3>\1</h3>", content, flags=re.MULTILINE)
                content = content.replace("\n", "<br>")
                return f"<html><body>{content}</body></html>"

        return (
            "<h1>API Markdown documentation not found</h1><p>Please generate documentation first.</p>",
            404,
        )

    except Exception as e:
        return f"<h1>Error</h1><p>Failed to serve API markdown: {str(e)}</p>", 500


@docs_bp.route("/generate")
def generate_documentation():
    """Endpoint to trigger documentation generation."""
    try:
        # Run the documentation generation script
        result = subprocess.run(
            [sys.executable, "scripts/docs/generate_docs.py"],
            capture_output=True,
            text=True,
            cwd=str(PROJECT_ROOT),
        )

        if result.returncode == 0:
            return jsonify(
                {
                    "success": True,
                    "message": "Documentation generated successfully!",
                    "output": result.stdout,
                }
            )
        else:
            return (
                jsonify(
                    {
                        "success": False,
                        "message": "Documentation generation failed",
                        "error": result.stderr,
                        "output": result.stdout,
                    }
                ),
                500,
            )

    except Exception as e:
        return (
            jsonify(
                {
                    "success": False,
                    "message": "Failed to generate documentation",
                    "error": str(e),
                }
            ),
            500,
        )


@docs_bp.route("/status")
def docs_status():
    """Get the status of available documentation files."""
    try:
        status = {
            "docs_directory": str(DOCS_DIR),
            "public_docs_directory": str(PUBLIC_DOCS_DIR),
            "files": {
                "openapi_spec": False,
                "react_components_json": False,
                "react_components_html": False,
                "api_markdown": False,
                "index_html": False,
            },
            "last_generated": None,
        }

        # Check for files in both directories
        files_to_check = {
            "openapi_spec": "openapi.json",
            "react_components_json": "react-components.json",
            "react_components_html": "react-components.html",
            "api_markdown": "api_docs.md",
            "index_html": "index.html",
        }

        for key, filename in files_to_check.items():
            for docs_path in [PUBLIC_DOCS_DIR, DOCS_DIR]:
                file_path = docs_path / filename
                if file_path.exists():
                    status["files"][key] = True
                    # Get the most recent modification time
                    mtime = file_path.stat().st_mtime
                    if status["last_generated"] is None or mtime > status["last_generated"]:
                        status["last_generated"] = mtime
                    break

        # Convert timestamp to readable format
        if status["last_generated"]:
            status["last_generated"] = datetime.datetime.fromtimestamp(status["last_generated"]).isoformat()

        return jsonify(status)

    except Exception as e:
        return jsonify({"error": f"Failed to get documentation status: {str(e)}"}), 500


@docs_bp.route("/<path:filename>")
def serve_doc_file(filename):
    """Serve any documentation file."""
    try:
        # Only serve files with specific documentation extensions
        allowed_extensions = {
            ".html",
            ".json",
            ".md",
            ".txt",
            ".css",
            ".js",
            ".png",
            ".jpg",
            ".jpeg",
            ".gif",
            ".svg",
            ".ico",
        }
        file_ext = Path(filename).suffix.lower()

        if file_ext not in allowed_extensions:
            # If it's not a documentation file, let other routes_http handle it
            abort(404)

        # Try to serve from public/docs first, then fallback to docs/
        for docs_path in [PUBLIC_DOCS_DIR, DOCS_DIR]:
            if docs_path.exists():
                try:
                    return send_from_directory(str(docs_path), filename)
                except NotFound:
                    continue

        return jsonify({"error": f"Documentation file '{filename}' not found"}), 404

    except Exception as e:
        return jsonify({"error": f"Failed to serve documentation file: {str(e)}"}), 500


# Error handlers for the documentation blueprint
@docs_bp.errorhandler(404)
def docs_not_found(error):
    """Custom 404 handler for documentation routes_http."""
    return (
        jsonify(
            {
                "error": "Documentation not found",
                "message": "The requested documentation file does not exist. Try generating the documentation first.",
                "generate_url": "/docs/generate",
            }
        ),
        404,
    )


@docs_bp.errorhandler(500)
def docs_server_error(error):
    """Custom 500 handler for documentation routes_http."""
    return (
        jsonify(
            {
                "error": "Documentation server error",
                "message": "An error occurred while serving the documentation.",
            }
        ),
        500,
    )


docs_routes = docs_bp
