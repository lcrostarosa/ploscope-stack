#!/bin/bash

# PLOSolver GitHub Container Registry Setup Script
# This script helps set up and manage the GitHub Container Registry for PLOSolver

set -e

# Colors for output
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# Default values
REGISTRY="docker.io"
DEFAULT_REPOSITORY="your-username/PLOSolver"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "PLOSolver GitHub Container Registry Setup Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  login              - Login to GitHub Container Registry"
    echo "  build              - Build and push images to registry"
    echo "  pull               - Pull images from registry"
    echo "  deploy-staging     - Deploy to staging using registry images"
    echo "  deploy-production  - Deploy to production using registry images"
    echo "  list               - List available images in registry"
    echo "  cleanup            - Clean up unused images"
    echo "  setup              - Complete setup (login + build + deploy)"
    echo ""
    echo "Options:"
    echo "  --repository REPO  - GitHub repository (default: $DEFAULT_REPOSITORY)"
    echo "  --tag TAG          - Image tag (default: latest)"
    echo "  --environment ENV  - Environment (staging/production)"
    echo "  --help             - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 login"
    echo "  $0 build --environment staging"
    echo "  $0 deploy-staging --repository lucascrostarosa/PLOSolver"
    echo "  $0 setup --environment production"
}

# Function to check if required environment variables are set
check_env_vars() {
    local missing_vars=()
    
    if [ -z "$GITHUB_TOKEN" ]; then
        missing_vars+=("GITHUB_TOKEN")
    fi
    
    if [ -z "$GITHUB_ACTOR" ]; then
        missing_vars+=("GITHUB_ACTOR")
    fi
    
    if [ -z "$GITHUB_REPOSITORY" ]; then
        missing_vars+=("GITHUB_REPOSITORY")
    fi
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        print_error "Missing required environment variables: ${missing_vars[*]}"
        echo ""
        echo "Please set the following environment variables:"
        echo "  export GITHUB_TOKEN=your_github_token"
        echo "  export GITHUB_ACTOR=your_github_username"
        echo "  export GITHUB_REPOSITORY=your_username/PLOSolver"
        echo ""
        echo "Or run this script from a GitHub Actions environment."
        exit 1
    fi
}

# Function to login to registry
login_registry() {
    print_status "Logging into GitHub Container Registry..."
    
    if [ -z "$GITHUB_TOKEN" ]; then
        print_error "GITHUB_TOKEN environment variable is required"
        exit 1
    fi
    
    echo "$GITHUB_TOKEN" | docker login "$REGISTRY" -u "$GITHUB_ACTOR" --password-stdin
    
    if [ $? -eq 0 ]; then
        print_success "Successfully logged into $REGISTRY"
    else
        print_error "Failed to login to $REGISTRY"
        exit 1
    fi
}

# Function to build and push images
build_images() {
    local environment=${1:-staging}
    local tag=${2:-latest}
    
    print_status "Building and pushing images for environment: $environment"
    
    # Set environment-specific tags
    if [ "$environment" = "staging" ]; then
        frontend_tag="staging-frontend"
        backend_tag="staging-backend"
    else
        frontend_tag="latest-frontend"
        backend_tag="latest-backend"
    fi
    
    # Build and push frontend
    print_status "Building frontend image..."
    docker build -f src/frontend/Dockerfile \
        -t "$REGISTRY/$GITHUB_REPOSITORY-frontend:$frontend_tag" \
        src/frontend
        --build-arg NODE_ENV=production \
        --build-arg REACT_APP_API_URL=/api \
        --build-arg REACT_APP_FEATURE_TRAINING_MODE_ENABLED=false \
        --build-arg REACT_APP_FEATURE_SOLVER_MODE_ENABLED=true \
        --build-arg REACT_APP_FEATURE_PLAYER_PROFILES_ENABLED=false \
        --build-arg REACT_APP_FEATURE_HAND_HISTORY_ANALYZER_ENABLED=false \
        --build-arg REACT_APP_FEATURE_TOURNAMENT_MODE_ENABLED=true \
        --build-arg REACT_APP_FEATURE_CASH_GAME_MODE_ENABLED=false \
        --build-arg REACT_APP_FEATURE_CUSTOM_MODE_ENABLED=false \
        -t "$REGISTRY/$GITHUB_REPOSITORY-frontend:$frontend_tag" .
    
    # Build and push backend
    print_status "Building backend image..."
    docker build -f src/backend/Dockerfile \
        --build-arg BUILD_ENV=production \
        -t "$REGISTRY/$GITHUB_REPOSITORY-backend:$backend_tag" \
        src/backend
    
    # Push images
    print_status "Pushing images to registry..."
    docker push "$REGISTRY/$GITHUB_REPOSITORY-frontend:$frontend_tag"
    docker push "$REGISTRY/$GITHUB_REPOSITORY-backend:$backend_tag"
    
    print_success "Successfully built and pushed images:"
    echo "  Frontend: $REGISTRY/$GITHUB_REPOSITORY-frontend:$frontend_tag"
    echo "  Backend: $REGISTRY/$GITHUB_REPOSITORY-backend:$backend_tag"
}

# Function to pull images
pull_images() {
    local environment=${1:-staging}
    
    print_status "Pulling images for environment: $environment"
    
    # Set environment-specific tags
    if [ "$environment" = "staging" ]; then
        frontend_tag="staging-frontend"
        backend_tag="staging-backend"
    else
        frontend_tag="latest-frontend"
        backend_tag="latest-backend"
    fi
    
    # Pull images
    docker pull "$REGISTRY/$GITHUB_REPOSITORY-frontend:$frontend_tag"
    docker pull "$REGISTRY/$GITHUB_REPOSITORY-backend:$backend_tag"
    
    print_success "Successfully pulled images:"
    echo "  Frontend: $REGISTRY/$GITHUB_REPOSITORY-frontend:$frontend_tag"
    echo "  Backend: $REGISTRY/$GITHUB_REPOSITORY-backend:$backend_tag"
}

# Function to deploy to staging
deploy_staging() {
    print_status "Deploying to staging environment..."
    
    # Login to registry
    login_registry
    
    # Pull latest images
    pull_images "staging"
    
    # Deploy using docker-compose
    print_status "Starting staging deployment..."
    GITHUB_REPOSITORY="$GITHUB_REPOSITORY" docker compose --env-file env.staging up -d
    
    print_success "Staging deployment completed!"
    echo "  Frontend: http://ploscope.com"
    echo "  Traefik Dashboard: http://ploscope.com:8080"
}

# Function to deploy to production
deploy_production() {
    print_status "Deploying to production environment..."
    
    # Login to registry
    login_registry
    
    # Pull latest images
    pull_images "production"
    
    # Deploy using docker-compose
    print_status "Starting production deployment..."
    GITHUB_REPOSITORY="$GITHUB_REPOSITORY" docker compose --env-file env.production up -d
    
    print_success "Production deployment completed!"
    echo "  Frontend: https://ploscope.com"
    echo "  Traefik Dashboard: https://ploscope.com:8080"
}

# Function to list images
list_images() {
    print_status "Listing images in registry..."
    
    # This would require GitHub API access to list packages
    # For now, we'll show the expected image names
    echo "Expected images in registry:"
    echo "  Frontend: $REGISTRY/$GITHUB_REPOSITORY-frontend"
    echo "  Backend: $REGISTRY/$GITHUB_REPOSITORY-backend"
    echo ""
    echo "Available tags:"
    echo "  - staging-frontend"
    echo "  - staging-backend"
    echo "  - latest-frontend"
    echo "  - latest-backend"
    echo "  - v*.*.*-frontend (for releases)"
    echo "  - v*.*.*-backend (for releases)"
}

# Function to cleanup unused images
cleanup_images() {
    print_status "Cleaning up unused Docker images..."
    
    docker image prune -f
    
    print_success "Cleanup completed!"
}

# Function to complete setup
complete_setup() {
    local environment=${1:-staging}
    
    print_status "Starting complete setup for environment: $environment"
    
    # Check environment variables
    check_env_vars
    
    # Login to registry
    login_registry
    
    # Build and push images
    build_images "$environment"
    
    # Deploy
    if [ "$environment" = "staging" ]; then
        deploy_staging
    else
        deploy_production
    fi
    
    print_success "Complete setup finished!"
}

# Main script logic
main() {
    local command=""
    local repository="$DEFAULT_REPOSITORY"
    local tag="latest"
    local environment="staging"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            login|build|pull|deploy-staging|deploy-production|list|cleanup|setup)
                command="$1"
                shift
                ;;
            --repository)
                repository="$2"
                shift 2
                ;;
            --tag)
                tag="$2"
                shift 2
                ;;
            --environment)
                environment="$2"
                shift 2
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Set repository if not already set
    if [ -z "$GITHUB_REPOSITORY" ]; then
        export GITHUB_REPOSITORY="$repository"
    fi
    
    # Execute command
    case "$command" in
        login)
            login_registry
            ;;
        build)
            build_images "$environment" "$tag"
            ;;
        pull)
            pull_images "$environment"
            ;;
        deploy-staging)
            deploy_staging
            ;;
        deploy-production)
            deploy_production
            ;;
        list)
            list_images
            ;;
        cleanup)
            cleanup_images
            ;;
        setup)
            complete_setup "$environment"
            ;;
        "")
            print_error "No command specified"
            show_usage
            exit 1
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