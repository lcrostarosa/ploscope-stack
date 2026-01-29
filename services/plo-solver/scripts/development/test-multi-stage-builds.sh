#!/bin/bash

# Test script for multi-stage Docker builds
set -e

echo "🐳 Testing multi-stage Docker builds..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to get image size
get_image_size() {
    local image_name=$1
    docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep "$image_name" | awk '{print $2}' || echo "N/A"
}

# Function to build and measure image
build_and_measure() {
    local service=$1
    local dockerfile=$2
    local tag="plosolver-${service}-test"
    
    echo -e "${YELLOW}📦 Building ${service}...${NC}"
    
    # Remove existing image if it exists
    docker rmi "$tag" 2>/dev/null || true
    
    # Build the image
    docker build -f "$dockerfile" -t "$tag" . --no-cache
    
    # Get image size
    local size=$(get_image_size "$tag")
    echo -e "${GREEN}✅ ${service} build completed. Size: ${size}${NC}"
    
    # Store size for comparison
    echo "$size" > "/tmp/${service}_size.txt"
}

# Build all services
echo -e "${YELLOW}🔨 Building all services with multi-stage builds...${NC}"

build_and_measure "frontend" "src/frontend/Dockerfile"
build_and_measure "backend" "src/backend/Dockerfile"
build_and_measure "celery" "src/celery/Dockerfile"

# Display results
echo -e "\n${GREEN}📊 Multi-stage build results:${NC}"
echo "=================================="
echo "Frontend: $(cat /tmp/frontend_size.txt 2>/dev/null || echo 'N/A')"
echo "Backend:  $(cat /tmp/backend_size.txt 2>/dev/null || echo 'N/A')"
echo "Celery:   $(cat /tmp/celery_size.txt 2>/dev/null || echo 'N/A')"

# Cleanup
rm -f /tmp/*_size.txt

echo -e "\n${GREEN}✅ Multi-stage build test completed!${NC}"
echo -e "${YELLOW}💡 To clean up test images, run:${NC}"
echo "docker rmi plosolver-frontend-test plosolver-backend-test plosolver-celery-test" 