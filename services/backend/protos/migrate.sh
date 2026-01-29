#!/bin/bash

# PLOSolver Proto Migration Script
# This script helps migrate from the monolithic plosolver.proto to the modular structure

set -e

echo "PLOSolver Proto Migration Script"
echo "================================="
echo ""

# Check if protoc is installed
if ! command -v protoc &> /dev/null; then
    echo "Error: protoc is not installed. Please install Protocol Buffers compiler."
    exit 1
fi

# Function to generate code for all routes_grpc
generate_all() {
    echo "Generating code for all services..."
    protoc --go_out=. --go-grpc_out=. *.proto
    echo "✓ Code generation completed for all services"
}

# Function to generate code for specific domains
generate_domains() {
    local domains=("$@")
    echo "Generating code for domains: ${domains[*]}"

    for domain in "${domains[@]}"; do
        if [ -f "${domain}.proto" ]; then
            echo "  Generating ${domain}.proto..."
            protoc --go_out=. --go-grpc_out=. "${domain}.proto"
        else
            echo "  Warning: ${domain}.proto not found"
        fi
    done
    echo "✓ Code generation completed for specified domains"
}

# Function to validate proto files
validate_protos() {
    echo "Validating proto files..."

    local proto_files=("common.proto" "auth.proto" "solver.proto" "job.proto" "subscription.proto" "hand_history.proto" "core.proto")

    for file in "${proto_files[@]}"; do
        if [ -f "$file" ]; then
            echo "  Validating $file..."
            protoc --proto_path=. "$file" --descriptor_set_out=/dev/null
        else
            echo "  Warning: $file not found"
        fi
    done

    echo "✓ Proto validation completed"
}

# Main script logic
case "${1:-help}" in
    "all")
        generate_all
        ;;
    "domains")
        shift
        if [ $# -eq 0 ]; then
            echo "Error: Please specify domains to generate"
            echo "Usage: $0 domains common auth solver"
            exit 1
        fi
        generate_domains "$@"
        ;;
    "validate")
        validate_protos
        ;;
    "help"|*)
        echo "Usage: $0 {all|domains|validate|help}"
        echo ""
        echo "Commands:"
        echo "  all      - Generate code for all services"
        echo "  domains  - Generate code for specific domains (e.g., $0 domains common auth)"
        echo "  validate - Validate all proto files"
        echo "  help     - Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 all"
        echo "  $0 domains common auth solver"
        echo "  $0 validate"
        ;;
esac
