#!/bin/bash

# Test script to verify Semgrep SARIF output generation
# This script tests the semgrep SARIF functionality locally

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo "🔍 Testing Semgrep SARIF Output Generation"
echo "=========================================="

# Check if we're in the right directory
if [ ! -f "Jenkinsfile" ]; then
    print_error "This script must be run from the project root directory"
    echo "   Current directory: $(pwd)"
    echo "   Expected: Project root with Jenkinsfile present"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if semgrep is installed
if ! command_exists semgrep; then
    print_status "Installing semgrep..."
    pip install --user semgrep
    export PATH=$PATH:$HOME/.local/bin
fi

# Create test directory
TEST_DIR="semgrep-test-results"
mkdir -p "$TEST_DIR"

print_status "Testing semgrep SARIF output generation..."

# Test 1: Basic SARIF output
print_status "Test 1: Generating SARIF output..."
if semgrep scan --config=auto --sarif --sarif-output="$TEST_DIR/semgrep-test.sarif" . 2>/dev/null; then
    if [ -f "$TEST_DIR/semgrep-test.sarif" ]; then
        print_success "SARIF file generated successfully"
        
        # Check if SARIF file has valid content
        if [ -s "$TEST_DIR/semgrep-test.sarif" ]; then
            print_success "SARIF file contains data"
            
            # Check if it's valid JSON
            if python3 -m json.tool "$TEST_DIR/semgrep-test.sarif" >/dev/null 2>&1; then
                print_success "SARIF file contains valid JSON"
            else
                print_warning "SARIF file may not contain valid JSON"
            fi
        else
            print_warning "SARIF file is empty (no findings)"
        fi
    else
        print_error "SARIF file was not created"
    fi
else
    print_error "Failed to generate SARIF output"
fi

# Test 2: JSON output for comparison
print_status "Test 2: Generating JSON output for comparison..."
if semgrep scan --config=auto --json --json-output="$TEST_DIR/semgrep-test.json" . 2>/dev/null; then
    if [ -f "$TEST_DIR/semgrep-test.json" ]; then
        print_success "JSON file generated successfully"
    else
        print_error "JSON file was not created"
    fi
else
    print_error "Failed to generate JSON output"
fi

# Test 3: Readable output
print_status "Test 3: Generating readable output..."
if semgrep scan --config=auto --text --text-output="$TEST_DIR/semgrep-test.txt" . 2>/dev/null; then
    if [ -f "$TEST_DIR/semgrep-test.txt" ]; then
        print_success "Readable output generated successfully"
    else
        print_error "Readable output was not created"
    fi
else
    print_error "Failed to generate readable output"
fi

# Test 4: Check semgrep version and capabilities
print_status "Test 4: Checking semgrep version and capabilities..."
SEMGREP_VERSION=$(semgrep --version 2>/dev/null | head -1)
print_success "Semgrep version: $SEMGREP_VERSION"

# Test 5: Validate SARIF schema (if jq is available)
if command_exists jq; then
    print_status "Test 5: Validating SARIF structure..."
    if [ -f "$TEST_DIR/semgrep-test.sarif" ]; then
        # Check for required SARIF fields
        if jq -e '.version' "$TEST_DIR/semgrep-test.sarif" >/dev/null 2>&1; then
            print_success "SARIF file has version field"
        else
            print_warning "SARIF file missing version field"
        fi
        
        if jq -e '.runs' "$TEST_DIR/semgrep-test.sarif" >/dev/null 2>&1; then
            print_success "SARIF file has runs field"
        else
            print_warning "SARIF file missing runs field"
        fi
    fi
else
    print_warning "jq not available, skipping SARIF structure validation"
fi

# Generate test report
print_status "Generating test report..."
cat > "$TEST_DIR/semgrep-test-report.md" << EOF
# Semgrep SARIF Test Report
Generated: $(date)

## Test Summary
This report contains the results of testing semgrep SARIF output generation.

## Files Generated
- \`semgrep-test.sarif\`: SARIF format output
- \`semgrep-test.json\`: JSON format output  
- \`semgrep-test.txt\`: Readable text output

## Test Results
- **SARIF Generation**: $(if [ -f "$TEST_DIR/semgrep-test.sarif" ]; then echo "✅ PASSED"; else echo "❌ FAILED"; fi)
- **JSON Generation**: $(if [ -f "$TEST_DIR/semgrep-test.json" ]; then echo "✅ PASSED"; else echo "❌ FAILED"; fi)
- **Readable Output**: $(if [ -f "$TEST_DIR/semgrep-test.txt" ]; then echo "✅ PASSED"; else echo "❌ FAILED"; fi)

## Semgrep Version
$SEMGREP_VERSION

## Next Steps
1. Review the generated files
2. Verify SARIF format is correct
3. Test with SARIF viewers/parsers
4. Integrate with Jenkins pipeline

EOF

print_success "Test report generated: $TEST_DIR/semgrep-test-report.md"

# Display file sizes
print_status "Generated file sizes:"
if [ -f "$TEST_DIR/semgrep-test.sarif" ]; then
    echo "  SARIF: $(wc -c < "$TEST_DIR/semgrep-test.sarif") bytes"
fi
if [ -f "$TEST_DIR/semgrep-test.json" ]; then
    echo "  JSON:  $(wc -c < "$TEST_DIR/semgrep-test.json") bytes"
fi
if [ -f "$TEST_DIR/semgrep-test.txt" ]; then
    echo "  Text:  $(wc -c < "$TEST_DIR/semgrep-test.txt") bytes"
fi

print_success "Semgrep SARIF testing completed!"
echo ""
echo "📁 Test results saved in: $TEST_DIR/"
echo "📋 Report: $TEST_DIR/semgrep-test-report.md"
echo ""
echo "🔍 To view SARIF results:"
echo "  - VS Code: Install 'SARIF Viewer' extension"
echo "  - Online: Use https://microsoft.github.io/sarif-web-component/"
echo "  - Command line: jq '.runs[].results[] | {rule: .rule.id, message: .message.text, location: .locations[].physicalLocation.artifactLocation.uri}' $TEST_DIR/semgrep-test.sarif" 