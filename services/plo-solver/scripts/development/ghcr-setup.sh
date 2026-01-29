#!/bin/bash

# GitHub Container Registry (GHCR) Setup and Management Script
# This script helps with GHCR authentication, image management, and deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Load environment variables from env.ghcr if it exists
if [ -f "env.ghcr" ]; then
    print_status "Loading environment variables from env.ghcr"
    export $(grep -v '^#' env.ghcr | xargs)
fi

# Configuration
GITHUB_USERNAME=${GITHUB_USERNAME:-}
GITHUB_TOKEN=${GITHUB_TOKEN:-}
REGISTRY=${GHCR_REGISTRY:-"ghcr.io"}
REPOSITORY=${GITHUB_REPOSITORY:-$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^/]*\/[^/]*\).*/\1/')}
ENVIRONMENT=${ENVIRONMENT:-development}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_status "Docker is running"
}

# Function to authenticate with GHCR
authenticate_ghcr() {
    print_header "Authenticating with GitHub Container Registry"
    
    if [ -z "$GITHUB_TOKEN" ]; then
        print_warning "GITHUB_TOKEN not set. Please provide your GitHub Personal Access Token:"
        read -s GITHUB_TOKEN
        echo
    fi
    
    if [ -z "$GITHUB_USERNAME" ]; then
        print_warning "GITHUB_USERNAME not set. Please provide your GitHub username:"
        read GITHUB_USERNAME
    fi
    
    echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin
    
    if [ $? -eq 0 ]; then
        print_status "Successfully authenticated with GHCR"
    else
        print_error "Failed to authenticate with GHCR"
        exit 1
    fi
}

# Function to build and push images locally
build_and_push_local() {
    print_header "Building and Pushing Images Locally"
    
    local image_type=$1
    local tag=${2:-latest}
    
    if [ -z "$image_type" ]; then
        print_error "Please specify image type (frontend or backend)"
        exit 1
    fi
    
    local image_name="$REGISTRY/$REPOSITORY-$image_type:$tag"
    
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
        *)
            print_error "Invalid image type: $image_type. Use 'frontend' or 'backend'"
            exit 1
            ;;
    esac
    
    print_status "Pushing $image_name..."
    docker push "$image_name"
    
    print_status "Successfully built and pushed $image_name"
}

# Function to pull images from GHCR
pull_images() {
    print_header "Pulling Images from GHCR"
    
    local image_type=$1
    local tag=${2:-latest}
    
    if [ -z "$image_type" ]; then
        print_error "Please specify image type (frontend or backend)"
        exit 1
    fi
    
    local image_name="$REGISTRY/$REPOSITORY-$image_type:$tag"
    
    print_status "Pulling $image_name..."
    docker pull "$image_name"
    
    if [ $? -eq 0 ]; then
        print_status "Successfully pulled $image_name"
    else
        print_error "Failed to pull $image_name"
        exit 1
    fi
}

# Function to list available images
list_images() {
    print_header "Available Images in GHCR"
    
    local image_type=$1
    
    if [ -z "$image_type" ]; then
        print_status "Listing all images for repository: $REPOSITORY"
        curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/user/packages?package_type=container" | \
            jq -r ".[] | select(.name | contains(\"$REPOSITORY\")) | .name"
    else
        print_status "Listing $image_type images for repository: $REPOSITORY"
        curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/user/packages?package_type=container" | \
            jq -r ".[] | select(.name | contains(\"$REPOSITORY-$image_type\")) | .name"
    fi
}

# Function to update docker-compose to use GHCR images
update_docker_compose() {
    print_header "Updating Docker Compose to Use GHCR Images"
    
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
    sed -i.bak "s|image: ghcr.io/\${GITHUB_REPOSITORY:-your-username/PLOSolver}-frontend:\${ENVIRONMENT:-development}|image: ploscope/frontend:${ENVIRONMENT:-development}|g" "$compose_file"
    
    # Update backend service to use DockerHub image
    sed -i.bak "s|image: ghcr.io/\${GITHUB_REPOSITORY:-your-username/PLOSolver}-backend:\${ENVIRONMENT:-development}|image: ploscope/backend:${ENVIRONMENT:-development}|g" "$compose_file"
    
    # Clean up temporary files
    rm -f "$compose_file.bak"
    
    print_status "Updated $compose_file to use GHCR images"
    print_warning "Please review the changes before running docker-compose"
}

# Function to show usage
show_usage() {
    echo "GitHub Container Registry (GHCR) Setup and Management Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  auth                    Authenticate with GHCR"
    echo "  build [frontend|backend] [tag]  Build and push image locally"
    echo "  pull [frontend|backend] [tag]   Pull image from GHCR"
    echo "  list [frontend|backend]         List available images"
    echo "  update-compose                  Update docker-compose.yml to use GHCR images"
    echo "  setup                          Complete setup (auth + update-compose)"
    echo "  help                           Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  GITHUB_USERNAME          Your GitHub username"
    echo "  GITHUB_TOKEN             Your GitHub Personal Access Token"
    echo "  GITHUB_REPOSITORY        Repository name (auto-detected from git)"
    echo "  ENVIRONMENT              Environment tag (default: development)"
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
            authenticate_ghcr
            ;;
        "build")
            check_docker
            authenticate_ghcr
            build_and_push_local "$arg1" "$arg2"
            ;;
        "pull")
            check_docker
            authenticate_ghcr
            pull_images "$arg1" "$arg2"
            ;;
        "list")
            authenticate_ghcr
            list_images "$arg1"
            ;;
        "update-compose")
            update_docker_compose
            ;;
        "setup")
            check_docker
            authenticate_ghcr
            update_docker_compose
            print_status "Setup complete! You can now use 'docker-compose up' with GHCR images"
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