#!/bin/bash

# ===========================================
# Generate CI Environment Variable Commands
# ===========================================
# This script generates the exact commands to set CI environment variables
# Run these commands manually if the automated script doesn't work

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}${NC}"
}

# Function to get current repository
get_repo() {
    local repo
    repo=$(git remote get-url origin | sed 's/.*github\.com[:/]\([^/]*\/[^/]*\)\.git/\1/')
    
    if [[ -z "$repo" ]]; then
        print_status $RED "Could not determine current repository."
        exit 1
    fi
    
    echo "$repo"
}

# Function to generate variable setting commands
generate_variable_commands() {
    local repo=$(get_repo)
    local env_file="env.development"
    
    if [[ ! -f "$env_file" ]]; then
        print_status $RED "Environment file not found: $env_file"
        exit 1
    fi
    
    print_status $BLUE "Generating commands to set CI environment variables"
    print_status $BLUE "Repository: $repo"
    echo
    
    # Create output file
    local output_file="ci-variables-commands.sh"
    
    # Write header
    cat > "$output_file" << EOF
#!/bin/bash
# ===========================================
# CI Environment Variables Setup Commands
# ===========================================
# Run these commands to set CI environment variables
# Make sure you have the right permissions first

set -euo pipefail

echo "Setting CI environment variables for $repo"
echo

EOF
    
    # Read the environment file and generate commands
    local count=0
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        if [[ -z "$key" ]] || [[ "$key" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Remove leading/trailing whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        # Skip if key or value is empty
        if [[ -z "$key" ]] || [[ -z "$value" ]]; then
            continue
        fi
        
        # Generate the command
        echo "echo \"Setting $key...\"" >> "$output_file"
        echo "gh api --method PUT \"repos/$repo/environments/ci/variables/$key\" \\" >> "$output_file"
        echo "  --field value=\"$value\"" >> "$output_file"
        echo "echo \"✅ Set $key\"" >> "$output_file"
        echo "" >> "$output_file"
        
        ((count++))
    done < "$env_file"
    
    # Write footer
    cat >> "$output_file" << EOF
echo "🎉 Set $count CI environment variables successfully!"
echo
echo "Next steps:"
echo "1. Set required secrets in GitHub UI:"
echo "   https://github.com/$repo/settings/environments/ci"
echo "2. Test the CI pipeline"
EOF
    
    # Make the file executable
    chmod +x "$output_file"
    
    print_status $GREEN "✅ Generated $output_file with $count variable commands"
    print_status $YELLOW "Run: ./$output_file"
}

# Function to generate secret setting commands
generate_secret_commands() {
    local repo=$(get_repo)
    local output_file="ci-secrets-commands.sh"
    
    print_status $BLUE "Generating commands to set CI environment secrets"
    echo
    
    # Create output file
    cat > "$output_file" << EOF
#!/bin/bash
# ===========================================
# CI Environment Secrets Setup Commands
# ===========================================
# Run these commands to set CI environment secrets
# You'll need to provide the actual secret values

set -euo pipefail

echo "Setting CI environment secrets for $repo"
echo "Note: You'll need to provide the actual secret values"
echo

EOF
    
    # List of required secrets
    local secrets=(
        "DB_PASSWORD=postgres"
        "SECRET_KEY=dev-secret-key-change-in-production"
        "JWT_SECRET_KEY=your-jwt-secret-key-here"
        "STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key_here"
        "STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key_here"
        "STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here"
    )
    
    for secret in "${secrets[@]}"; do
        local key="${secret%%=*}"
        local default_value="${secret#*=}"
        
        echo "echo \"Setting $key...\"" >> "$output_file"
        echo "echo \"Enter value for $key (default: $default_value):\"" >> "$output_file"
        echo "read -p \"> \" secret_value" >> "$output_file"
        echo "if [[ -z \"\$secret_value\" ]]; then" >> "$output_file"
        echo "  secret_value=\"$default_value\"" >> "$output_file"
        echo "fi" >> "$output_file"
        echo "gh secret set $key --env ci --body \"\$secret_value\"" >> "$output_file"
        echo "echo \"✅ Set $key\"" >> "$output_file"
        echo "" >> "$output_file"
    done
    
    # Write footer
    cat >> "$output_file" << EOF
echo "🎉 Set all CI environment secrets successfully!"
echo
echo "Next steps:"
echo "1. Test the CI pipeline"
echo "2. Monitor workflows to ensure they use the correct environment values"
EOF
    
    # Make the file executable
    chmod +x "$output_file"
    
    print_status $GREEN "✅ Generated $output_file with secret commands"
    print_status $YELLOW "Run: ./$output_file"
}

# Function to generate manual setup instructions
generate_manual_instructions() {
    local repo=$(get_repo)
    local output_file="ci-manual-setup.md"
    
    print_status $BLUE "Generating manual setup instructions"
    echo
    
    cat > "$output_file" << EOF
# Manual CI Environment Setup

## Repository: $repo

## Step 1: Create CI Environment (if not exists)

1. Go to: https://github.com/$repo/settings/environments
2. Click "New environment"
3. Name: \`ci\`
4. Leave protection rules unchecked
5. Click "Configure environment"

## Step 2: Set Environment Variables

### Option A: Use Generated Script
\`\`\`bash
./ci-variables-commands.sh
\`\`\`

### Option B: Manual Setup
Go to: https://github.com/$repo/settings/environments/ci

Add these variables from \`env.development\`:

EOF
    
    # Read the environment file and list variables
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        if [[ -z "$key" ]] || [[ "$key" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Remove leading/trailing whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        # Skip if key or value is empty
        if [[ -z "$key" ]] || [[ -z "$value" ]]; then
            continue
        fi
        
        echo "- \`$key\` = \`$value\`" >> "$output_file"
    done < "env.development"
    
    cat >> "$output_file" << EOF

## Step 3: Set Environment Secrets

### Option A: Use Generated Script
\`\`\`bash
./ci-secrets-commands.sh
\`\`\`

### Option B: Manual Setup
Go to: https://github.com/$repo/settings/environments/ci

Add these secrets:

- \`DB_PASSWORD\` = \`postgres\`
- \`SECRET_KEY\` = \`dev-secret-key-change-in-production\`
- \`JWT_SECRET_KEY\` = \`your-jwt-secret-key-here\`
- \`STRIPE_SECRET_KEY\` = \`sk_test_your_stripe_secret_key_here\`
- \`STRIPE_PUBLISHABLE_KEY\` = \`pk_test_your_stripe_publishable_key_here\`
- \`STRIPE_WEBHOOK_SECRET\` = \`whsec_your_webhook_secret_here\`

## Step 4: Verify Setup

1. Check that all variables and secrets are set
2. Test a workflow that uses the \`ci\` environment
3. Monitor the workflow to ensure it uses correct values

## Troubleshooting

If you get permission errors:
1. Ensure you have admin access to the repository
2. Check that your GitHub token has the right scopes
3. Try setting variables manually in the GitHub UI
EOF
    
    print_status $GREEN "✅ Generated $output_file with manual instructions"
    print_status $YELLOW "See: $output_file"
}

# Main function
main() {
    print_status $BLUE "🚀 Generating CI environment setup commands"
    echo
    
    # Get repository info
    local repo
    repo=$(get_repo)
    print_status $GREEN "Working with repository: $repo"
    echo
    
    # Generate commands
    generate_variable_commands
    echo
    
    generate_secret_commands
    echo
    
    generate_manual_instructions
    echo
    
    print_status $GREEN "🎉 Generated all setup files!"
    echo
    print_status $BLUE "Files created:"
    echo "  - ci-variables-commands.sh (run to set variables)"
    echo "  - ci-secrets-commands.sh (run to set secrets)"
    echo "  - ci-manual-setup.md (manual instructions)"
    echo
    print_status $YELLOW "Next steps:"
    echo "  1. Run: ./ci-variables-commands.sh"
    echo "  2. Run: ./ci-secrets-commands.sh"
    echo "  3. Or follow manual instructions in ci-manual-setup.md"
}

# Run main function
main "$@" 