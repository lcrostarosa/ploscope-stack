#!/usr/bin/env bash
# Clone all PLOScope repositories for local development
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(dirname "$SCRIPT_DIR")"
REPOS_DIR="${STACK_DIR}/repos"

# Define all repositories
# Format: "repo-name:branch"
REPOS=(
    "backend:main"
    "frontend:main"
    "core:main"
    "nexus:main"
    "database:main"
    "db-init:main"
    "traefik:main"
    "monitoring:main"
    "redis:main"
    "rabbitmq:main"
    "rabbitmq-init:main"
    "celery-worker:main"
    "jenkins:main"
    "ansible:main"
    "plo-solver:main"
    "vault:main"
)

GITHUB_ORG="PLOScope"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║           PLOScope Repository Cloner                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Create repos directory
mkdir -p "$REPOS_DIR"
cd "$REPOS_DIR"

echo "📁 Cloning repositories to: $REPOS_DIR"
echo ""

# Track results
SUCCESS=()
FAILED=()
SKIPPED=()

for repo_spec in "${REPOS[@]}"; do
    IFS=':' read -r repo branch <<< "$repo_spec"
    
    if [[ -d "$repo" ]]; then
        echo "⏭️  Skipping $repo (already exists)"
        SKIPPED+=("$repo")
        continue
    fi
    
    echo -n "📥 Cloning $repo..."
    if gh repo clone "${GITHUB_ORG}/${repo}" -- --branch "$branch" 2>/dev/null; then
        echo " ✅"
        SUCCESS+=("$repo")
    else
        echo " ❌"
        FAILED+=("$repo")
    fi
done

echo ""
echo "════════════════════════════════════════════════════════════"
echo "Summary:"
echo "  ✅ Cloned:  ${#SUCCESS[@]}"
echo "  ⏭️  Skipped: ${#SKIPPED[@]}"
echo "  ❌ Failed:  ${#FAILED[@]}"

if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo ""
    echo "Failed repositories:"
    for repo in "${FAILED[@]}"; do
        echo "  - $repo"
    done
    echo ""
    echo "Make sure you have access to the PLOScope organization."
    echo "Try: gh auth status"
fi

echo ""
echo "Done! You can now run: ./scripts/dev.sh up"
