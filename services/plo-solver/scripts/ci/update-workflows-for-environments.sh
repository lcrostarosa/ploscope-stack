#!/bin/bash

# ===========================================
# Update Workflows for Environment Integration
# ===========================================
# This script helps update existing GitHub Actions workflows to use
# environment variables and secrets from GitHub environments.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORKFLOWS_DIR=".github/workflows"
BACKUP_DIR=".github/workflows/backup"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}${NC}"
}

# Function to create backup
create_backup() {
    local file=$1
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
    fi
    
    local backup_file="$BACKUP_DIR/$(basename "$file").backup.$(date +%Y%m%d_%H%M%S)"
    cp "$file" "$backup_file"
    print_status $GREEN "✅ Backup created: $backup_file"
}

# Function to update staging deployment workflow
update_staging_workflow() {
    local file="$WORKFLOWS_DIR/staging-deploy.yml"
    
    if [[ ! -f "$file" ]]; then
        print_status $YELLOW "Staging workflow not found: $file"
        return
    fi
    
    print_status $BLUE "Updating staging deployment workflow..."
    create_backup "$file"
    
    # Create updated workflow content
    cat > "$file" << 'EOF'
name: Staging Deployment

on:
  push:
    branches: [ master ]
  workflow_dispatch:
    inputs:
      force_deploy:
        description: 'Force deployment even if no changes'
        required: false
        default: false
        type: boolean

env:
  REGISTRY: docker.io
  IMAGE_NAME_FRONTEND: ${{ github.repository }}-frontend
  IMAGE_NAME_BACKEND: ${{ github.repository }}-backend

jobs:
  # Run tests before deployment
  test:
    runs-on: self-hosted
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '24.x'
        cache: 'npm'
        cache-dependency-path: 'src/frontend/package-lock.json'

    - name: Setup Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.11'

    - name: Install dependencies
      run: |
        cd src/frontend && npm ci
        cd ../backend && pip install -r requirements.txt -r requirements-test.txt

    - name: Run frontend tests
      run: make test-frontend

    - name: Run backend tests
      run: make test-unit

    - name: Build frontend with environment variables
      env:
        NODE_ENV: production
        REACT_APP_API_URL: ${{ vars.REACT_APP_API_URL || '/api' }}
        REACT_APP_FEATURE_TRAINING_MODE_ENABLED: ${{ vars.REACT_APP_FEATURE_TRAINING_MODE_ENABLED || 'false' }}
        REACT_APP_FEATURE_SOLVER_MODE_ENABLED: ${{ vars.REACT_APP_FEATURE_SOLVER_MODE_ENABLED || 'true' }}
        REACT_APP_FEATURE_PLAYER_PROFILES_ENABLED: ${{ vars.REACT_APP_FEATURE_PLAYER_PROFILES_ENABLED || 'false' }}
        REACT_APP_FEATURE_HAND_HISTORY_ANALYZER_ENABLED: ${{ vars.REACT_APP_FEATURE_HAND_HISTORY_ANALYZER_ENABLED || 'false' }}
        REACT_APP_FEATURE_TOURNAMENT_MODE_ENABLED: ${{ vars.REACT_APP_FEATURE_TOURNAMENT_MODE_ENABLED || 'false' }}
        REACT_APP_FEATURE_CASH_GAME_MODE_ENABLED: ${{ vars.REACT_APP_FEATURE_CASH_GAME_MODE_ENABLED || 'false' }}
        REACT_APP_FEATURE_CUSTOM_MODE_ENABLED: ${{ vars.REACT_APP_FEATURE_CUSTOM_MODE_ENABLED || 'false' }}
      run: cd src/frontend && npm run build

  # Deploy to staging
  deploy:
    runs-on: self-hosted
    needs: test
    if: github.ref == 'refs/heads/master' || github.event.inputs.force_deploy == 'true'
    environment: staging  # This triggers protection rules
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: Log in to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}

    - name: Build and push frontend image
      uses: docker/build-push-action@v5
      with:
        context: ./src/frontend
        file: Dockerfile
        build-args: |
          BUILD_ENV=staging
          REACT_APP_API_URL=${{ vars.REACT_APP_API_URL || '/api' }}
        push: true
        tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME_FRONTEND }}:staging
        cache-from: type=gha
        cache-to: type=gha,mode=max

    - name: Build and push backend image
      uses: docker/build-push-action@v5
      with:
        context: ./src/backend
        file: Dockerfile
        build-args: |
          BUILD_ENV=staging
        push: true
        tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME_BACKEND }}:staging
        cache-from: type=gha
        cache-to: type=gha,mode=max

    - name: Setup SSH
      uses: webfactory/ssh-agent@v0.8.0
      with:
        ssh-private-key: ${{ secrets.STAGING_DEPLOY_KEY }}

    - name: Deploy to staging
      env:
        # Access environment-specific variables
        ENVIRONMENT: ${{ vars.ENVIRONMENT }}
        FRONTEND_URL: ${{ vars.FRONTEND_URL }}
        # Access environment-specific secrets
        STAGING_DB_PASSWORD: ${{ secrets.STAGING_DB_PASSWORD }}
        STRIPE_SECRET_KEY: ${{ secrets.STRIPE_SECRET_KEY }}
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      run: |
        echo "🚀 Deploying to staging environment..."
        echo "Environment: $ENVIRONMENT"
        echo "Frontend URL: $FRONTEND_URL"
        echo "Using images:"
        echo "  Frontend: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME_FRONTEND }}:staging"
        echo "  Backend: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME_BACKEND }}:staging"
        
        # Create deployment script on the server
        cat > deploy-staging.sh << 'DEPLOY_EOF'
        #!/bin/bash
        set -e
        
        echo "📦 Updating code from repository..."
        cd ${{ vars.STAGING_PATH || '/opt/plosolver' }}
        git fetch origin
        git reset --hard origin/master
        
        echo "🔧 Building and deploying application..."
        make staging-deploy
        
        echo "✅ Staging deployment completed successfully!"
        echo "🌐 Application available at: ${{ vars.FRONTEND_URL }}"
        DEPLOY_EOF
        
        # Copy deployment script to server
        scp deploy-staging.sh ${{ vars.STAGING_USER || 'deploy' }}@${{ vars.STAGING_HOST || 'staging.plosolver.com' }}:/tmp/
        
        # Execute deployment on server
        ssh ${{ vars.STAGING_USER || 'deploy' }}@${{ vars.STAGING_HOST || 'staging.plosolver.com' }} << 'SSH_EOF'
          chmod +x /tmp/deploy-staging.sh
          /tmp/deploy-staging.sh
          rm /tmp/deploy-staging.sh
        SSH_EOF

    - name: Health check
      run: |
        echo "🏥 Performing health check..."
        sleep 30  # Wait for deployment to complete
        
        # Check if the application is responding
        for i in {1..5}; do
          if curl -f -s ${{ vars.FRONTEND_URL }} > /dev/null; then
            echo "✅ Application is healthy and responding"
            break
          else
            echo "⏳ Waiting for application to be ready... (attempt $i/5)"
            sleep 10
          fi
        done
        
        # Final health check
        if ! curl -f -s ${{ vars.FRONTEND_URL }} > /dev/null; then
          echo "❌ Application health check failed"
          exit 1
        fi

    - name: Notify deployment status
      if: always()
      run: |
        if [ "${{ job.status }}" == "success" ]; then
          echo "🎉 Staging deployment completed successfully!"
          echo "🌐 Application: ${{ vars.FRONTEND_URL }}"
          echo "📊 Traefik Dashboard: ${{ vars.FRONTEND_URL }}:8080"
        else
          echo "❌ Staging deployment failed!"
          exit 1
        fi
EOF

    print_status $GREEN "✅ Staging workflow updated successfully"
}

# Function to update CI workflow
update_ci_workflow() {
    local file="$WORKFLOWS_DIR/ci.yml"
    
    if [[ ! -f "$file" ]]; then
        print_status $YELLOW "CI workflow not found: $file"
        return
    fi
    
    print_status $BLUE "Updating CI workflow to use environment variables..."
    create_backup "$file"
    
    # Update the frontend build step to use environment variables
    sed -i.bak 's/REACT_APP_API_URL=\/api/REACT_APP_API_URL=${{ vars.REACT_APP_API_URL || "\/api" }}/g' "$file"
    sed -i.bak 's/REACT_APP_FEATURE_TRAINING_MODE_ENABLED=false/REACT_APP_FEATURE_TRAINING_MODE_ENABLED=${{ vars.REACT_APP_FEATURE_TRAINING_MODE_ENABLED || "false" }}/g' "$file"
    sed -i.bak 's/REACT_APP_FEATURE_SOLVER_MODE_ENABLED=true/REACT_APP_FEATURE_SOLVER_MODE_ENABLED=${{ vars.REACT_APP_FEATURE_SOLVER_MODE_ENABLED || "true" }}/g' "$file"
    sed -i.bak 's/REACT_APP_FEATURE_PLAYER_PROFILES_ENABLED=false/REACT_APP_FEATURE_PLAYER_PROFILES_ENABLED=${{ vars.REACT_APP_FEATURE_PLAYER_PROFILES_ENABLED || "false" }}/g' "$file"
    sed -i.bak 's/REACT_APP_FEATURE_HAND_HISTORY_ANALYZER_ENABLED=false/REACT_APP_FEATURE_HAND_HISTORY_ANALYZER_ENABLED=${{ vars.REACT_APP_FEATURE_HAND_HISTORY_ANALYZER_ENABLED || "false" }}/g' "$file"
    sed -i.bak 's/REACT_APP_FEATURE_TOURNAMENT_MODE_ENABLED=true/REACT_APP_FEATURE_TOURNAMENT_MODE_ENABLED=${{ vars.REACT_APP_FEATURE_TOURNAMENT_MODE_ENABLED || "false" }}/g' "$file"
    sed -i.bak 's/REACT_APP_FEATURE_CASH_GAME_MODE_ENABLED=false/REACT_APP_FEATURE_CASH_GAME_MODE_ENABLED=${{ vars.REACT_APP_FEATURE_CASH_GAME_MODE_ENABLED || "false" }}/g' "$file"
    sed -i.bak 's/REACT_APP_FEATURE_CUSTOM_MODE_ENABLED=false/REACT_APP_FEATURE_CUSTOM_MODE_ENABLED=${{ vars.REACT_APP_FEATURE_CUSTOM_MODE_ENABLED || "false" }}/g' "$file"
    
    # Remove backup file
    rm -f "$file.bak"
    
    print_status $GREEN "✅ CI workflow updated successfully"
}

# Function to show help
show_help() {
    cat << EOF
Update Workflows for Environment Integration

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -s, --staging           Update staging deployment workflow
    -c, --ci                Update CI workflow
    -a, --all               Update all workflows
    -b, --backup-only       Create backups only (no updates)

EXAMPLES:
    $0 --all                    # Update all workflows
    $0 --staging               # Update staging workflow only
    $0 --ci                    # Update CI workflow only
    $0 --backup-only           # Create backups only

NOTES:
    - Backups are automatically created before updates
    - Backups are stored in .github/workflows/backup/
    - Original files are preserved with timestamp

EOF
}

# Main function
main() {
    local update_staging=false
    local update_ci=false
    local backup_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -s|--staging)
                update_staging=true
                shift
                ;;
            -c|--ci)
                update_ci=true
                shift
                ;;
            -a|--all)
                update_staging=true
                update_ci=true
                shift
                ;;
            -b|--backup-only)
                backup_only=true
                shift
                ;;
            *)
                print_status $RED "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # If no specific options, show help
    if [[ "$update_staging" == "false" ]] && [[ "$update_ci" == "false" ]] && [[ "$backup_only" == "false" ]]; then
        print_status $YELLOW "No options specified. Use --help for usage information."
        show_help
        exit 1
    fi
    
    print_status $BLUE "🔄 Updating workflows for environment integration..."
    
    # Create backups
    if [[ "$update_staging" == "true" ]]; then
        if [[ -f "$WORKFLOWS_DIR/staging-deploy.yml" ]]; then
            create_backup "$WORKFLOWS_DIR/staging-deploy.yml"
        fi
    fi
    
    if [[ "$update_ci" == "true" ]]; then
        if [[ -f "$WORKFLOWS_DIR/ci.yml" ]]; then
            create_backup "$WORKFLOWS_DIR/ci.yml"
        fi
    fi
    
    # Exit if backup only
    if [[ "$backup_only" == "true" ]]; then
        print_status $GREEN "✅ Backups created successfully"
        exit 0
    fi
    
    # Update workflows
    if [[ "$update_staging" == "true" ]]; then
        update_staging_workflow
    fi
    
    if [[ "$update_ci" == "true" ]]; then
        update_ci_workflow
    fi
    
    print_status $GREEN "🎉 Workflow updates completed successfully!"
    echo
    print_status $BLUE "Next steps:"
    echo "  1. Review the updated workflows"
    echo "  2. Set up GitHub environments: ./scripts/setup-github-environments.sh --all"
    echo "  3. Configure secrets: ./scripts/setup-github-secrets.sh staging --interactive"
    echo "  4. Test the deployment process"
    echo
    print_status $YELLOW "For more information, see: docs/05-architecture/2025-01-20-ci-environment-integration.md"
}

# Run main function with all arguments
main "$@" 