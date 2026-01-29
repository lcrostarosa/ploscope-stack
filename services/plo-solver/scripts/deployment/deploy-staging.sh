#!/bin/bash
# Automated Staging Deployment Script for PLOSolver
# This script automates the manual SSH deployment process

set -e

# Colors for output
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# Configuration
STAGING_HOST="${STAGING_HOST:-ploscope.com}"
STAGING_USER="${STAGING_USER:-root}"
STAGING_PATH="${STAGING_PATH:-/root/plo-solver}"
SSH_KEY_PATH="${SSH_KEY_PATH:-~/.ssh/id_ed25519}"

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

# Function to check if SSH key exists and is accessible
check_ssh_key() {
    if [ ! -f "$SSH_KEY_PATH" ]; then
        print_error "SSH key not found at $SSH_KEY_PATH"
        print_status "Please ensure your SSH private key is available"
        exit 1
    fi
    
    if [ ! -r "$SSH_KEY_PATH" ]; then
        print_error "SSH key at $SSH_KEY_PATH is not readable"
        print_status "Please check file permissions: chmod 600 $SSH_KEY_PATH"
        exit 1
    fi
}

# Function to test SSH connection
test_ssh_connection() {
    print_status "Testing SSH connection to $STAGING_USER@$STAGING_HOST..."
    
    if ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=10 -o BatchMode=yes "$STAGING_USER@$STAGING_HOST" "echo 'SSH connection successful'" 2>/dev/null; then
        print_success "SSH connection established"
        return 0
    else
        print_error "SSH connection failed"
        print_status "Please check:"
        print_status "1. SSH key is correct and has proper permissions"
        print_status "2. Server is accessible at $STAGING_HOST"
        print_status "3. User $STAGING_USER has access"
        return 1
    fi
}

# Function to handle SSH key password (if needed)
handle_ssh_key_password() {
    if ssh-add -l | grep -q "$(ssh-keygen -lf "$SSH_KEY_PATH" | awk '{print $2}')"; then
        print_success "SSH key already loaded in ssh-agent"
        return 0
    fi
    
    print_status "SSH key not loaded in ssh-agent"
    print_status "Attempting to add SSH key to ssh-agent..."
    
    if ssh-add "$SSH_KEY_PATH" 2>/dev/null; then
        print_success "SSH key added to ssh-agent"
        return 0
    else
        print_warning "Could not add SSH key to ssh-agent automatically"
        print_status "You may be prompted for your SSH key password during deployment"
        return 0
    fi
}

# Function to deploy to staging
deploy_to_staging() {
    print_status "Starting staging deployment..."
    
    # Create deployment script content
    local deploy_script=$(cat << 'EOF'
#!/bin/bash
set -e

echo "🚀 Starting PLOSolver staging deployment..."

# Navigate to project directory
cd /root/plo-solver

# Pull latest changes from master branch
echo "📦 Pulling latest changes from repository..."
git fetch origin
git reset --hard origin/master

# Stop existing containers (if running)
echo "🛑 Stopping existing containers..."
docker-compose down || true

# Clean up any dangling images/containers
echo "🧹 Cleaning up Docker resources..."
docker system prune -f || true

# Build and deploy
echo "🔧 Building and deploying application..."
make staging-deploy

# Wait a moment for containers to start
echo "⏳ Waiting for containers to start..."
sleep 10

# Check if containers are running
echo "🏥 Checking container health..."
if docker-compose ps | grep -q "Up"; then
    echo "✅ Containers are running successfully"
else
    echo "❌ Some containers failed to start"
    docker-compose ps
    exit 1
fi

echo "✅ Staging deployment completed successfully!"
echo "🌐 Application available at: https://ploscope.com"
echo "📊 Traefik Dashboard: https://ploscope.com:8080"
EOF
)

    # Copy deployment script to server and execute
    print_status "Copying deployment script to server..."
    echo "$deploy_script" | ssh -i "$SSH_KEY_PATH" "$STAGING_USER@$STAGING_HOST" "cat > /tmp/deploy-staging.sh && chmod +x /tmp/deploy-staging.sh"
    
    print_status "Executing deployment on server..."
    ssh -i "$SSH_KEY_PATH" "$STAGING_USER@$STAGING_HOST" "/tmp/deploy-staging.sh"
    
    # Clean up deployment script
    ssh -i "$SSH_KEY_PATH" "$STAGING_USER@$STAGING_HOST" "rm -f /tmp/deploy-staging.sh"
}

# Function to perform health check
perform_health_check() {
    print_status "Performing health check..."
    
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        print_status "Health check attempt $attempt/$max_attempts..."
        
        if curl -f -s -m 10 https://ploscope.com > /dev/null 2>&1; then
            print_success "Application is healthy and responding"
            return 0
        else
            print_warning "Application not responding yet (attempt $attempt/$max_attempts)"
            sleep 10
            ((attempt++))
        fi
    done
    
    print_error "Health check failed after $max_attempts attempts"
    return 1
}

# Function to show deployment status
show_deployment_status() {
    print_status "Checking deployment status..."
    
    ssh -i "$SSH_KEY_PATH" "$STAGING_USER@$STAGING_HOST" << 'EOF'
        echo "=== Docker Container Status ==="
        docker-compose ps
        
        echo ""
        echo "=== Recent Application Logs ==="
        docker-compose logs --tail=20
        
        echo ""
        echo "=== System Resources ==="
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
EOF
}

# Main deployment function
main() {
    echo -e "${GREEN}🚀 PLOSolver Staging Deployment${NC}"
    echo "=================================="
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    check_ssh_key
    handle_ssh_key_password
    
    # Test connection
    if ! test_ssh_connection; then
        exit 1
    fi
    
    # Confirm deployment
    echo ""
    print_warning "This will deploy the current master branch to staging"
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Deployment cancelled"
        exit 0
    fi
    
    # Perform deployment
    deploy_to_staging
    
    # Health check
    if perform_health_check; then
        print_success "Staging deployment completed successfully!"
        echo ""
        print_status "Deployment Summary:"
        echo "  🌐 Application: https://ploscope.com"
        echo "  📊 Traefik Dashboard: https://ploscope.com:8080"
        echo "  🐳 Docker Status: Check with 'docker compose ps'"
    else
        print_error "Deployment may have issues. Checking status..."
        show_deployment_status
        exit 1
    fi
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --status       Show deployment status without deploying"
        echo "  --health       Perform health check only"
        echo ""
        echo "Environment Variables:"
        echo "  STAGING_HOST   Staging server hostname (default: ploscope.com)"
        echo "  STAGING_USER   SSH user (default: root)"
        echo "  STAGING_PATH   Project path on server (default: /root/plo-solver)"
        echo "  SSH_KEY_PATH   Path to SSH private key (default: ~/.ssh/id_ed25519)"
        exit 0
        ;;
    --status)
        check_ssh_key
        show_deployment_status
        exit 0
        ;;
    --health)
        perform_health_check
        exit $?
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown option: $1"
        print_status "Use --help for usage information"
        exit 1
        ;;
esac 