#!/bin/bash

# Newman Integration Tests Runner
# This script runs the Newman integration tests against the local PLOSolver backend

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COLLECTION_FILE="postman/PLOSolver-Integration-Tests.postman_collection.json"
ENVIRONMENT_FILE="postman/PLOSolver-CI-Environment.postman_environment.json"
RESULTS_FILE="newman-results.json"
BACKEND_URL="http://localhost"

echo -e "${BLUE}🚀 Starting Newman Integration Tests${NC}"
echo "=================================="

# Check if Newman is installed
if ! command -v newman &> /dev/null; then
    echo -e "${YELLOW}⚠️  Newman not found - installing globally...${NC}"
    npm install -g newman --silent --no-progress
fi

# Check if collection file exists
if [ ! -f "$COLLECTION_FILE" ]; then
    echo -e "${RED}❌ Collection file not found: $COLLECTION_FILE${NC}"
    exit 1
fi

# Check if environment file exists
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo -e "${RED}❌ Environment file not found: $ENVIRONMENT_FILE${NC}"
    exit 1
fi

# Check if backend is running
echo -e "${YELLOW}🔍 Checking if backend is running at $BACKEND_URL...${NC}"
if ! curl -s "$BACKEND_URL/api/health" > /dev/null; then
    echo -e "${RED}❌ Backend is not running at $BACKEND_URL${NC}"
    echo -e "${YELLOW}💡 Make sure to start the backend with: make run-local${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Backend is running${NC}"

# Run Newman tests
echo -e "${YELLOW}🧪 Running Newman tests...${NC}"
echo "Collection: $COLLECTION_FILE"
echo "Environment: $ENVIRONMENT_FILE"
echo "Results: $RESULTS_FILE"
echo ""

# Run Newman with both CLI and JSON reporters
newman run "$COLLECTION_FILE" \
    -e "$ENVIRONMENT_FILE" \
    --reporters cli,json \
    --reporter-json-export "$RESULTS_FILE" \
    --timeout-request 30000 \
    --timeout-script 30000

# Check exit code
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ All Newman tests passed!${NC}"
    echo -e "${BLUE}📊 Results saved to: $RESULTS_FILE${NC}"
    
    # Show summary
    echo ""
    echo -e "${BLUE}📋 Test Summary:${NC}"
    echo "=================="
    echo -e "✅ Health Check"
    echo -e "✅ User Registration"
    echo -e "✅ User Login"
    echo -e "✅ Submit Spot Simulation Job"
    echo -e "✅ Get Job Status"
    echo -e "✅ Get Recent Jobs"
    echo -e "✅ Submit Solver Analysis Job"
    echo -e "✅ Test Invalid Job Submission"
    
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some Newman tests failed${NC}"
    echo -e "${BLUE}📊 Results saved to: $RESULTS_FILE${NC}"
    echo -e "${YELLOW}💡 Check the output above for details${NC}"
    exit 1
fi 