#!/bin/bash

set -euo pipefail

BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

echo -e "${BLUE}📦 Publishing plosolver-core to Nexus via Twine${NC}"

cd "$(dirname "$0")/../../src/plosolver_core"

if ! command -v twine >/dev/null 2>&1; then
  echo -e "${RED}❌ twine is not installed. Install with: pip install twine build${NC}"
  exit 1
fi

# Build against public PyPI to resolve build tools cleanly (can override via PIP_BUILD_INDEX_URL)
export PIP_INDEX_URL="${PIP_BUILD_INDEX_URL:-https://pypi.org/simple}"
rm -rf dist build *.egg-info || true
python -m build

export TWINE_REPOSITORY_URL="${TWINE_REPOSITORY_URL:-${NEXUS_URL:-https://nexus.ploscope.com}/repository/pypi-internal/}"
export TWINE_USERNAME="${TWINE_USERNAME:-${NEXUS_USERNAME:-}}"
export TWINE_PASSWORD="${TWINE_PASSWORD:-${NEXUS_PASSWORD:-${NEXUS_PYPI_PASSWORD:-}}}"

if [ -z "${TWINE_USERNAME}" ] || [ -z "${TWINE_PASSWORD}" ]; then
  echo -e "${RED}❌ Missing credentials. Set TWINE_USERNAME and TWINE_PASSWORD (recommended) or NEXUS_USERNAME/NEXUS_PASSWORD.${NC}"
  exit 2
fi

echo -e "${BLUE}🚀 Uploading to: ${TWINE_REPOSITORY_URL}${NC}"
python -m twine upload --repository-url "${TWINE_REPOSITORY_URL}" dist/*

echo -e "${GREEN}✅ Upload complete${NC}"


