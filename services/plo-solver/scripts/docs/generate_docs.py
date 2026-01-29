#!/usr/bin/env python3
"""
Unified Documentation Generator

Generates both API documentation and React component documentation,
then creates a unified documentation site.
"""

import os
import sys
import subprocess
import json
from pathlib import Path

# Add backend to path to import our modules
backend_path = Path(__file__).parent.parent / "backend"
sys.path.append(str(backend_path))

try:
    from scripts.api_docs_generator import generate_docs_for_app
    # Backend-local app factory
    sys.path.append(str(backend_path))
    from app import create_app
    app = create_app()
except ImportError as e:
    print(f"⚠️  Could not import backend modules: {e}")
    print("Make sure you're running this from the project root.")
    sys.exit(1)


def setup_docs_directory():
    """Create and setup the docs directory."""
    docs_dir = Path("..") / "docs"
    docs_dir.mkdir(exist_ok=True)
    
    # Create public directory if it doesn't exist
    public_docs = Path("..") / "public" / "docs"
    public_docs.mkdir(parents=True, exist_ok=True)
    
    return docs_dir, public_docs


def generate_api_documentation(docs_dir):
    """Generate API documentation."""
    print("🔌 Generating API documentation...")
    
    try:
        # Use Flask app context to generate docs
        with app.app_context():
            openapi_spec = generate_docs_for_app(app, str(docs_dir))
            print(f"✅ API documentation generated successfully!")
            return True
    except Exception as e:
        print(f"❌ Failed to generate API documentation: {e}")
        return False


def generate_react_documentation(docs_dir):
    """Generate React component documentation."""
    print("⚛️  Generating React documentation...")
    
    try:
        # Run the Node.js React documentation generator
        result = subprocess.run([
            'node', 'react_docs_generator.js'
        ], capture_output=True, text=True, cwd=os.path.dirname(__file__))
        
        if result.returncode == 0:
            print("✅ React documentation generated successfully!")
            return True
        else:
            print(f"❌ Failed to generate React documentation: {result.stderr}")
            return False
    except FileNotFoundError:
        print("⚠️  Node.js not found. Skipping React documentation generation.")
        return False
    except Exception as e:
        print(f"❌ Error generating React documentation: {e}")
        return False


def copy_docs_to_public(docs_dir, public_docs):
    """Copy generated documentation to public directory for serving."""
    print("📋 Copying documentation to public directory...")
    
    try:
        import shutil
        
        # Copy all files from docs to public/docs
        for file_path in docs_dir.glob("*"):
            if file_path.is_file():
                shutil.copy2(file_path, public_docs)
        
        print("✅ Documentation copied to public directory!")
        return True
    except Exception as e:
        print(f"❌ Failed to copy documentation: {e}")
        return False


def generate_documentation_index(docs_dir, public_docs):
    """Generate an index page for the documentation."""
    print("📄 Generating documentation index...")
    
    index_html = """
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
            max-width: 800px;
            margin: 0 auto;
            background: white;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #2d3748;
            text-align: center;
            margin-bottom: 30px;
        }
        .docs-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-top: 30px;
        }
        .doc-card {
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 20px;
            text-align: center;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .doc-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        .doc-card h3 {
            margin-top: 0;
            color: #4a5568;
        }
        .doc-card p {
            color: #718096;
            margin-bottom: 20px;
        }
        .doc-link {
            display: inline-block;
            background: #4299e1;
            color: white;
            padding: 10px 20px;
            text-decoration: none;
            border-radius: 6px;
            transition: background 0.2s;
        }
        .doc-link:hover {
            background: #3182ce;
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            color: #718096;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📚 PLOSolver Documentation</h1>
        <p style="text-align: center; color: #718096;">
            Welcome to the PLOSolver documentation hub. Choose the documentation type you'd like to explore.
        </p>
        
        <div class="docs-grid">
            <div class="doc-card">
                <h3>🔌 API Documentation</h3>
                <p>Complete API reference with interactive testing capabilities. Explore all endpoints, request/response formats, and test APIs directly.</p>
                <a href="openapi.json" class="doc-link" target="_blank">View OpenAPI Spec</a>
            </div>
            
            <div class="doc-card">
                <h3>⚛️ React Components</h3>
                <p>Interactive documentation for all React components, including props, hooks usage, and component relationships.</p>
                <a href="react-components.html" class="doc-link" target="_blank">View Components</a>
            </div>
        </div>
        
        <div class="footer">
            <p>Documentation generated automatically from source code</p>
            <p>Generated on: """ + str(__import__('datetime').datetime.now().strftime('%Y-%m-%d %H:%M:%S')) + """</p>
        </div>
    </div>
</body>
</html>
"""
    
    try:
        with open(docs_dir / "index.html", "w") as f:
            f.write(index_html)
        
        with open(public_docs / "index.html", "w") as f:
            f.write(index_html)
        
        print("✅ Documentation index generated!")
        return True
    except Exception as e:
        print(f"❌ Failed to generate documentation index: {e}")
        return False


def install_node_dependencies():
    """Install required Node.js dependencies for React documentation."""
    print("📦 Installing Node.js dependencies...")
    
    # Add required dependencies to package.json if they don't exist
    package_json_path = Path("..") / "src" / "frontend" / "package.json"
    if package_json_path.exists():
        try:
            with open(package_json_path, 'r') as f:
                package_data = json.load(f)
            
            # Check if babel dependencies exist
            dev_deps = package_data.get('devDependencies', {})
            required_deps = {
                '@babel/parser': '^7.24.0',
                '@babel/traverse': '^7.24.0',
                '@babel/types': '^7.24.0'
            }
            
            needs_install = False
            for dep, version in required_deps.items():
                if dep not in dev_deps:
                    dev_deps[dep] = version
                    needs_install = True
            
            if needs_install:
                package_data['devDependencies'] = dev_deps
                
                with open(package_json_path, 'w') as f:
                    json.dump(package_data, f, indent=2)
                
                # Install the new dependencies
                result = subprocess.run(['npm', 'install'], capture_output=True, text=True, cwd='../src/frontend')
                if result.returncode == 0:
                    print("✅ Node.js dependencies installed!")
                else:
                    print(f"⚠️  Failed to install Node.js dependencies: {result.stderr}")
            else:
                print("✅ Node.js dependencies already installed!")
                
        except Exception as e:
            print(f"⚠️  Could not update package.json: {e}")


def main():
    """Main documentation generation function."""
    print("🚀 Starting documentation generation...")
    print("=" * 50)
    
    # Setup directories
    docs_dir, public_docs = setup_docs_directory()
    
    # Install Node.js dependencies if needed
    install_node_dependencies()
    
    # Generate API documentation
    api_success = generate_api_documentation(docs_dir)
    
    # Generate React documentation
    react_success = generate_react_documentation(docs_dir)
    
    # Copy documentation to public directory
    copy_success = copy_docs_to_public(docs_dir, public_docs)
    
    # Generate documentation index
    index_success = generate_documentation_index(docs_dir, public_docs)
    
    print("=" * 50)
    
    if api_success or react_success:
        print("🎉 Documentation generation completed!")
        print(f"📁 Documentation available at: {docs_dir.absolute()}")
        print(f"🌐 Public documentation at: {public_docs.absolute()}")
        print("\n📋 Generated files:")
        
        for file_path in docs_dir.glob("*"):
            if file_path.is_file():
                print(f"   • {file_path.name}")
        
        print("\n💡 Tip: Start your Flask server and visit /docs to view the interactive documentation!")
    else:
        print("❌ Documentation generation failed!")
        sys.exit(1)


if __name__ == "__main__":
    main() 