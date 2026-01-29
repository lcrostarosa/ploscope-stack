#!/bin/bash

# Newman CI Environment Validation Script
# This script validates that Newman tests will work in the CI environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Validating Newman Tests for CI Environment${NC}"
echo "=============================================="

# Configuration
COLLECTION_FILE="postman/PLOSolver-Integration-Tests.postman_collection.json"
ENVIRONMENT_FILE="postman/PLOSolver-CI-Environment.postman_environment.json"
RESULTS_FILE="newman-report.json"
BACKEND_URL="http://localhost:5001"

# Check if Newman is installed
if ! command -v newman &> /dev/null; then
    echo -e "${RED}❌ Newman is not installed. Please install it with: npm install -g newman${NC}"
    exit 1
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

# Validate environment file structure
echo -e "${YELLOW}🔍 Validating environment file structure...${NC}"
if ! jq empty "$ENVIRONMENT_FILE" 2>/dev/null; then
    echo -e "${RED}❌ Environment file is not valid JSON${NC}"
    exit 1
fi

# Check for required environment variables
REQUIRED_VARS=("base_url")
for var in "${REQUIRED_VARS[@]}"; do
    if ! jq -e ".values[] | select(.key == \"$var\")" "$ENVIRONMENT_FILE" > /dev/null; then
        echo -e "${RED}❌ Required environment variable '$var' not found in $ENVIRONMENT_FILE${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✅ Environment file structure is valid${NC}"

# Validate collection file structure
echo -e "${YELLOW}🔍 Validating collection file structure...${NC}"
if ! jq empty "$COLLECTION_FILE" 2>/dev/null; then
    echo -e "${RED}❌ Collection file is not valid JSON${NC}"
    exit 1
fi

# Check for required collection properties
if ! jq -e '.info' "$COLLECTION_FILE" > /dev/null; then
    echo -e "${RED}❌ Collection file missing 'info' section${NC}"
    exit 1
fi

if ! jq -e '.item' "$COLLECTION_FILE" > /dev/null; then
    echo -e "${RED}❌ Collection file missing 'item' section${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Collection file structure is valid${NC}"

# Test with CI-like parameters
echo -e "${YELLOW}🧪 Running Newman tests with CI parameters...${NC}"
echo "Parameters:"
echo "  Collection: $COLLECTION_FILE"
echo "  Environment: $ENVIRONMENT_FILE"
echo "  Iteration Count: 1"
echo "  Timeout: 30000ms"
echo "  Request Timeout: 10000ms"
echo "  Reporters: cli,json"
echo ""

# Run Newman with CI parameters
newman run "$COLLECTION_FILE" \
    -e "$ENVIRONMENT_FILE" \
    --reporters cli,json \
    --reporter-json-export "$RESULTS_FILE" \
    --iteration-count 1 \
    --timeout 30000 \
    --timeout-request 10000

# Check exit code
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Newman tests passed with CI parameters!${NC}"
    
    # Validate JSON report structure
    if [ -f "$RESULTS_FILE" ]; then
        echo -e "${YELLOW}🔍 Validating JSON report structure...${NC}"
        if ! jq empty "$RESULTS_FILE" 2>/dev/null; then
            echo -e "${RED}❌ Generated JSON report is not valid${NC}"
            exit 1
        fi
        
        # Check for required report sections
        if ! jq -e '.run.stats' "$RESULTS_FILE" > /dev/null; then
            echo -e "${RED}❌ JSON report missing 'run.stats' section${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}✅ JSON report structure is valid${NC}"
        
        # Display test statistics
        echo -e "${BLUE}📊 Test Statistics:${NC}"
        echo "=================="
        jq -r '.run.stats | "Assertions: \(.assertions.total) total, \(.assertions.failed) failed"' "$RESULTS_FILE"
        jq -r '.run.stats | "Requests: \(.requests.total) total, \(.requests.failed) failed"' "$RESULTS_FILE"
        jq -r '.run.stats | "Tests: \(.tests.total) total, \(.tests.failed) failed"' "$RESULTS_FILE"
        
        # Check if all tests passed
        FAILED_ASSERTIONS=$(jq -r '.run.stats.assertions.failed' "$RESULTS_FILE")
        FAILED_REQUESTS=$(jq -r '.run.stats.requests.failed' "$RESULTS_FILE")
        FAILED_TESTS=$(jq -r '.run.stats.tests.failed' "$RESULTS_FILE")
        
        if [ "$FAILED_ASSERTIONS" -eq 0 ] && [ "$FAILED_REQUESTS" -eq 0 ] && [ "$FAILED_TESTS" -eq 0 ]; then
            echo -e "${GREEN}✅ All tests passed successfully!${NC}"
        else
            echo -e "${RED}❌ Some tests failed${NC}"
            exit 1
        fi
    fi
    
    echo ""
    echo -e "${GREEN}🎉 CI Environment Validation Complete!${NC}"
    echo -e "${BLUE}📋 Summary:${NC}"
    echo "=========="
    echo -e "✅ Backend connectivity verified"
    echo -e "✅ Environment file structure validated"
    echo -e "✅ Collection file structure validated"
    echo -e "✅ Newman tests executed successfully"
    echo -e "✅ JSON report generated and validated"
    echo -e "✅ All tests passed with CI parameters"
    echo ""
    echo -e "${BLUE}🚀 Ready for CI deployment!${NC}"
    
    exit 0
else
    echo ""
    echo -e "${RED}❌ Newman tests failed with CI parameters${NC}"
    echo -e "${YELLOW}💡 Check the output above for details${NC}"
    exit 1
fi 