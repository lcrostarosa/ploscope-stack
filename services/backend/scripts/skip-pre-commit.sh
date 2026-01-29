#!/bin/bash

# Script to temporarily skip pre-commit hooks
# Usage: ./scripts/skip-pre-commit.sh

echo "⚠️  Skipping pre-commit hooks for this commit..."
echo "Use: git commit --no-verify -m 'your message'"
echo ""
echo "Or set the environment variable:"
echo "export SKIP_PRE_COMMIT=true"
echo "git commit -m 'your message'"
echo ""
echo "⚠️  Remember to run the checks manually before pushing!"
