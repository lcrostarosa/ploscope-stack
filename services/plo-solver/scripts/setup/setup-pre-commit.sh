#!/bin/bash

# Setup pre-commit hook for PLOSolver
# This script installs pre-commit and configures the CI pipeline hook

set -e

echo "🔧 Setting up pre-commit hook for PLOSolver..."

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
    echo "📦 Installing pre-commit..."
    if command -v pip &> /dev/null; then
        pip install pre-commit
    elif command -v pip3 &> /dev/null; then
        pip3 install pre-commit
    else
        echo "❌ Error: pip not found. Please install Python and pip first."
        exit 1
    fi
else
    echo "✅ pre-commit already installed"
fi

# Install the pre-commit hooks
echo "🔗 Installing pre-commit hooks..."
pre-commit install --hook-type pre-commit
pre-commit install --hook-type pre-push

echo "✅ Pre-commit hook setup complete!"
echo ""
echo "📋 What this does:"
echo "  - Runs 'make ci-pipeline' before each commit"
echo "  - Runs 'make ci-pipeline' before each push"
echo "  - Prevents commits if the pipeline fails"
echo ""
echo "🚀 To run the CI pipeline manually:"
echo "  make ci-pipeline          # Full pipeline (Docker + tests)"
echo "  make ci-pipeline-quick    # Quick pipeline (no Docker)"
echo ""
echo "🔧 To skip the hook for a commit:"
echo "  git commit --no-verify -m 'your message'" 