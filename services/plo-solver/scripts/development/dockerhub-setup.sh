#!/bin/bash

# DockerHub Setup and Management Script
# This script helps manage Docker images in DockerHub

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_status() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Load environment variables from env.dockerhub if it exists
if [ -f "env.dockerhub" ]; then
    print_status "Loading environment variables from env.dockerhub"
    export $(grep -v '^#' env.dockerhub | xargs)
fi

# Configuration
DOCKERHUB_USERNAME=${DOCKERHUB_USERNAME:-}
DOCKERHUB_TOKEN=${DOCKERHUB_TOKEN:-}
REGISTRY=${DOCKERHUB_REGISTRY:-"docker.io"}
REPOSITORY=${DOCKERHUB_REPOSITORY:-"ploscope"}
ENVIRONMENT=${ENVIRONMENT:-development}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_status "Docker is running"
}

# Function to authenticate with DockerHub
authenticate_dockerhub() {
    print_header "Authenticating with DockerHub"
    
    if [ -z "$DOCKERHUB_TOKEN" ]; then
        print_warning "DOCKERHUB_TOKEN not set. Please provide your DockerHub Access Token:"
        read -s DOCKERHUB_TOKEN
        echo
    fi
    
    if [ -z "$DOCKERHUB_USERNAME" ]; then
        print_warning "DOCKERHUB_USERNAME not set. Please provide your DockerHub username:"
        read DOCKERHUB_USERNAME
    fi
    
    echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
    
    if [ $? -eq 0 ]; then
        print_status "Successfully authenticated with DockerHub"
    else
        print_error "Failed to authenticate with DockerHub"
        exit 1
    fi
}

# Function to build and push images locally
build_and_push_local() {
    print_header "Building and Pushing Images Locally"
    
    local image_type=$1
    local tag=${2:-latest}
    
    if [ -z "$image_type" ]; then
        print_error "Please specify image type (frontend, backend, or celery-worker)"
        exit 1
    fi
    
    local image_name="$REGISTRY/$REPOSITORY/$image_type:$tag"
    
    print_status "Building $image_name..."
    
    case $image_type in
        "frontend")
            docker build \
                --build-arg NODE_ENV=production \
                --build-arg REACT_APP_API_URL=/api \
                -f src/frontend/Dockerfile \
                -t "$image_name" .
            ;;
        "backend")
            docker build \
                --build-arg BUILD_ENV=production \
                -f src/backend/Dockerfile \
                -t "$image_name" .
            ;;
        "celery-worker")
            docker build \
                --build-arg BUILD_ENV=production \
                -f src/celery/Dockerfile \
                -t "$image_name" .
            ;;
        *)
            print_error "Invalid image type: $image_type. Use 'frontend', 'backend', or 'celery-worker'"
            exit 1
            ;;
    esac
    
    print_status "Pushing $image_name..."
    docker push "$image_name"
    
    print_status "Successfully built and pushed $image_name"
}

# Function to pull images from DockerHub
pull_images() {
    print_header "Pulling Images from DockerHub"
    
    local image_type=$1
    local tag=${2:-latest}
    
    if [ -z "$image_type" ]; then
        print_error "Please specify image type (frontend, backend, or celery-worker)"
        exit 1
    fi
    
    local image_name="$REGISTRY/$REPOSITORY/$image_type:$tag"
    
    print_status "Pulling $image_name..."
    docker pull "$image_name"
    
    print_status "Successfully pulled $image_name"
}

# Function to list available images
list_images() {
    print_header "Listing Available Images in DockerHub"
    
    local image_type=$1
    
    if [ -z "$image_type" ]; then
        print_info "Available images in $REPOSITORY:"
        docker search "$REPOSITORY" --filter=is-official=false --filter=is-automated=false
    else
        print_info "Available tags for $REPOSITORY/$image_type:"
        # Note: DockerHub API doesn't provide a direct way to list tags via CLI
        # This would require using the DockerHub API
        print_warning "Tag listing requires DockerHub API access. Please check manually at:"
        print_info "https://hub.docker.com/r/$REPOSITORY/$image_type/tags"
    fi
}

# Function to update docker-compose.yml to use DockerHub images
update_docker_compose() {
    print_header "Updating Docker Compose Files"
    
    local compose_file="docker-compose.yml"
    local backup_file="docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [ ! -f "$compose_file" ]; then
        print_error "Docker Compose file not found: $compose_file"
        exit 1
    fi
    
    # Create backup
    cp "$compose_file" "$backup_file"
    print_status "Created backup: $backup_file"
    
    # Update frontend service to use DockerHub image
    sed -i.bak "s|image: ghcr.io/\${GITHUB_REPOSITORY:-your-username/PLOSolver}-frontend:\${ENVIRONMENT:-development}|image: ploscope/frontend:\${ENVIRONMENT:-development}|g" "$compose_file"
    
    # Update backend service to use DockerHub image
    sed -i.bak "s|image: ghcr.io/\${GITHUB_REPOSITORY:-your-username/PLOSolver}-backend:\${ENVIRONMENT:-development}|image: ploscope/backend:\${ENVIRONMENT:-development}|g" "$compose_file"
    
    # Update celery worker to use DockerHub image
    sed -i.bak "s|build:|image: ploscope/celery-worker:\${ENVIRONMENT:-development}|g" "$compose_file"
    sed -i.bak "/context: \./d" "$compose_file"
    sed -i.bak "/dockerfile: src\/celery\/Dockerfile/d" "$compose_file"
    sed -i.bak "/args:/d" "$compose_file"
    sed -i.bak "/BUILDKIT_INLINE_CACHE: 1/d" "$compose_file"
    
    # Clean up temporary files
    rm -f "$compose_file.bak"
    
    print_status "Updated $compose_file to use DockerHub images"
    print_warning "Please review the changes before running docker-compose"
}

# Function to show usage
show_usage() {
    echo "DockerHub Setup and Management Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  auth                    Authenticate with DockerHub"
    echo "  build [frontend|backend|celery-worker] [tag]  Build and push image locally"
    echo "  pull [frontend|backend|celery-worker] [tag]   Pull image from DockerHub"
    echo "  list [frontend|backend|celery-worker]         List available images"
    echo "  update-compose                  Update docker-compose.yml to use DockerHub images"
    echo "  setup                          Complete setup (auth + update-compose)"
    echo "  help                           Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  DOCKERHUB_USERNAME          Your DockerHub username"
    echo "  DOCKERHUB_TOKEN             Your DockerHub Access Token"
    echo "  DOCKERHUB_REPOSITORY        Repository name (default: ploscope)"
    echo "  ENVIRONMENT                 Environment tag (default: development)"
    echo ""
    echo "Examples:"
    echo "  $0 auth"
    echo "  $0 build frontend latest"
    echo "  $0 build backend production"
    echo "  $0 pull frontend development"
    echo "  $0 setup"
}

# Main script logic
main() {
    local command=$1
    local arg1=$2
    local arg2=$3
    
    case $command in
        "auth")
            check_docker
            authenticate_dockerhub
            ;;
        "build")
            check_docker
            authenticate_dockerhub
            build_and_push_local "$arg1" "$arg2"
            ;;
        "pull")
            check_docker
            authenticate_dockerhub
            pull_images "$arg1" "$arg2"
            ;;
        "list")
            authenticate_dockerhub
            list_images "$arg1"
            ;;
        "update-compose")
            update_docker_compose
            ;;
        "setup")
            check_docker
            authenticate_dockerhub
            update_docker_compose
            print_status "Setup complete! You can now use 'docker-compose up' with DockerHub images"
            ;;
        "help"|"--help"|"-h"|"")
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 