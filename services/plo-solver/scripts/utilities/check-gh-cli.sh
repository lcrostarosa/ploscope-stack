#!/bin/bash

# Check if GitHub CLI is installed and authenticated
# Used by publishing targets in Makefile

set -e

# Colors
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Checking GitHub CLI setup...${NC}"

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
    echo ""
    echo -e "${YELLOW}📋 Installation instructions:${NC}"
    echo ""
    echo -e "${BLUE}macOS (Homebrew):${NC}"
    echo "  brew install gh"
    echo ""
    echo -e "${BLUE}Ubuntu/Debian:${NC}"
    echo "  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
    echo "  echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null"
    echo "  sudo apt update"
    echo "  sudo apt install gh"
    echo ""
    echo -e "${BLUE}Windows (Chocolatey):${NC}"
    echo "  choco install gh"
    echo ""
    echo -e "${BLUE}Or download from:${NC} https://github.com/cli/cli/releases"
    exit 1
fi

echo -e "${GREEN}✅ GitHub CLI is installed${NC}"

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  GitHub CLI is not authenticated${NC}"
    echo ""
    echo -e "${YELLOW}📋 To authenticate, run:${NC}"
    echo "  gh auth login"
    echo ""
    echo -e "${BLUE}Follow the prompts to authenticate with your GitHub account${NC}"
    exit 1
fi

echo -e "${GREEN}✅ GitHub CLI is authenticated${NC}"

# Check if we can access the repository
repo_url=$(git config --get remote.origin.url 2>/dev/null || echo "")
if [ -z "$repo_url" ]; then
    echo -e "${RED}❌ No git remote 'origin' found${NC}"
    exit 1
fi

# Extract owner/repo from URL
repo_path=$(echo "$repo_url" | sed 's/.*github\.com[:/]\([^.]*\)\.git.*/\1/')
if [ -z "$repo_path" ] || [ "$repo_path" = "$repo_url" ]; then
    echo -e "${RED}❌ Could not parse GitHub repository from remote URL: $repo_url${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Repository detected: $repo_path${NC}"

# Check if we can access the repository
if ! gh repo view "$repo_path" &> /dev/null; then
    echo -e "${RED}❌ Cannot access repository $repo_path${NC}"
    echo -e "${YELLOW}Make sure you have access to the repository and try authenticating again${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Repository access confirmed${NC}"
echo -e "${GREEN}🎉 All checks passed! Ready to publish packages${NC}"
