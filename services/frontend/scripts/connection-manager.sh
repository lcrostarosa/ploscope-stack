#!/bin/bash
# Frontend Connection Manager Script
# Manages SSH tunnels and environment connections for frontend development

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
STAGING_HOST="5.78.113.169"
STAGING_USER="appuser"
SSH_KEY="~/.ssh/plo-scope-staging"
LOCAL_DB_PORT="5433"
LOCAL_API_PORT="5002"
FRONTEND_PORT="3001"
STAGING_API_URL="https://staging.ploscope.com/api"

# Expand the tilde to the actual home directory path for SSH key
SSH_KEY_EXPANDED="${SSH_KEY/#\~/$HOME}"

# PID file for tracking tunnel processes
PID_FILE="/tmp/staging-tunnel.pid"
LOG_FILE="/tmp/staging-tunnel.log"

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

print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}  PLOScope Connection Manager${NC}"
    echo -e "${CYAN}================================${NC}"
}

# Function to check if a port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to check if SSH key exists
check_ssh_key() {
    if [ ! -f "$SSH_KEY_EXPANDED" ]; then
        print_error "SSH key not found at $SSH_KEY"
        print_warning "You need to:"
        echo -e "${BLUE}   1. Generate or copy your SSH private key to $SSH_KEY${NC}"
        echo -e "${BLUE}   2. Ensure the corresponding public key is in ~/.ssh/authorized_keys on the staging server${NC}"
        echo -e "${BLUE}   3. Set proper permissions: chmod 600 $SSH_KEY${NC}"
        echo ""
        print_status "After setting up the SSH key, run:"
        echo -e "${BLUE}   npm run tunnel:setup${NC}"
        return 1
    else
        print_success "SSH key found"
    fi
    return 0
}

# Function to test SSH connection
test_ssh_connection() {
    print_status "Testing SSH connection to staging server..."
    
    if ssh -i "$SSH_KEY_EXPANDED" -o ConnectTimeout=10 -o BatchMode=yes $STAGING_USER@$STAGING_HOST exit 2>/dev/null; then
        print_success "SSH connection successful"
        return 0
    else
        print_error "SSH connection failed"
        print_warning "Please check:"
        echo -e "${BLUE}   - SSH key permissions (should be 600)${NC}"
        echo -e "${BLUE}   - SSH key is added to staging server${NC}"
        echo -e "${BLUE}   - Network connectivity to $STAGING_HOST${NC}"
        echo ""
        print_status "To debug SSH issues, run:"
        echo -e "${BLUE}   ssh -v -i $SSH_KEY $STAGING_USER@$STAGING_HOST${NC}"
        echo -e "${BLUE}   This will show detailed connection information${NC}"
        return 1
    fi
}

# Function to start SSH tunnels
start_tunnels() {
    print_status "Starting SSH tunnels..."
    
    # Check if tunnels are already running
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 $pid 2>/dev/null; then
            print_warning "Tunnels are already running (PID: $pid)"
            return 0
        else
            print_status "Removing stale PID file"
            rm -f "$PID_FILE"
        fi
    fi
    
    # Check if ports are already in use
    if check_port $LOCAL_DB_PORT; then
        print_error "Port $LOCAL_DB_PORT is already in use"
        return 1
    fi
    
    # Start database tunnel
    print_status "Starting database tunnel on localhost:$LOCAL_DB_PORT..."
    ssh -i "$SSH_KEY_EXPANDED" -L $LOCAL_DB_PORT:localhost:5432 $STAGING_USER@$STAGING_HOST -N > "$LOG_FILE" 2>&1 &
    local tunnel_pid=$!
    
    # Wait for tunnel to establish
    sleep 3
    
    # Check if tunnel is working
    if check_port $LOCAL_DB_PORT; then
        echo $tunnel_pid > "$PID_FILE"
        print_success "Database tunnel established (PID: $tunnel_pid)"
        return 0
    else
        print_error "Database tunnel failed to establish"
        kill $tunnel_pid 2>/dev/null
        return 1
    fi
}

# Function to stop SSH tunnels
stop_tunnels() {
    print_status "Stopping SSH tunnels..."
    
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 $pid 2>/dev/null; then
            kill $pid
            print_success "Tunnels stopped (PID: $pid)"
        else
            print_warning "Tunnel process not found (PID: $pid)"
        fi
        rm -f "$PID_FILE"
    else
        print_warning "No tunnel PID file found"
    fi
    
    # Kill any remaining SSH processes for this connection
    pkill -f "ssh.*$STAGING_HOST.*$LOCAL_DB_PORT" 2>/dev/null || true
}

# Function to test database connection
test_database_connection() {
    print_status "Testing database connection..."
    
    if ! check_port $LOCAL_DB_PORT; then
        print_error "Database tunnel is not active"
        return 1
    fi
    
    # Test with netcat if available
    if command -v nc >/dev/null 2>&1; then
        if nc -zv localhost $LOCAL_DB_PORT 2>/dev/null; then
            print_success "Database connection successful"
            return 0
        else
            print_error "Database connection failed"
            return 1
        fi
    else
        print_warning "netcat not available, skipping database connection test"
        return 0
    fi
}

# Function to test API connection
test_api_connection() {
    print_status "Testing API connection..."
    
    if command -v curl >/dev/null 2>&1; then
        local response=$(curl -s -o /dev/null -w "%{http_code}" -H "Origin: http://localhost:$FRONTEND_PORT" "$STAGING_API_URL/health" 2>/dev/null)
        if [ "$response" = "200" ]; then
            print_success "API connection successful (HTTP $response)"
            return 0
        else
            print_error "API connection failed (HTTP $response)"
            return 1
        fi
    else
        print_warning "curl not available, skipping API connection test"
        return 0
    fi
}

# Function to show connection status
show_status() {
    print_header
    echo ""
    
    # Check SSH key
    echo -e "${CYAN}SSH Configuration:${NC}"
    if [ -f "$SSH_KEY_EXPANDED" ]; then
        echo -e "  SSH Key: ${GREEN}✓ Found${NC}"
    else
        echo -e "  SSH Key: ${RED}✗ Not found${NC}"
    fi
    
    # Check SSH connection
    echo -e "${CYAN}SSH Connection:${NC}"
    if ssh -i "$SSH_KEY_EXPANDED" -o ConnectTimeout=5 -o BatchMode=yes $STAGING_USER@$STAGING_HOST exit 2>/dev/null; then
        echo -e "  Staging Server: ${GREEN}✓ Connected${NC}"
    else
        echo -e "  Staging Server: ${RED}✗ Failed${NC}"
    fi
    
    # Check tunnels
    echo -e "${CYAN}SSH Tunnels:${NC}"
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 $pid 2>/dev/null; then
            echo -e "  Database Tunnel: ${GREEN}✓ Active (PID: $pid)${NC}"
        else
            echo -e "  Database Tunnel: ${RED}✗ Inactive${NC}"
        fi
    else
        echo -e "  Database Tunnel: ${YELLOW}✗ Not started${NC}"
    fi
    
    # Check ports
    echo -e "${CYAN}Port Status:${NC}"
    if check_port $LOCAL_DB_PORT; then
        echo -e "  Database Port ($LOCAL_DB_PORT): ${GREEN}✓ In use${NC}"
    else
        echo -e "  Database Port ($LOCAL_DB_PORT): ${YELLOW}✗ Available${NC}"
    fi
    
    if check_port $FRONTEND_PORT; then
        echo -e "  Frontend Port ($FRONTEND_PORT): ${GREEN}✓ In use${NC}"
    else
        echo -e "  Frontend Port ($FRONTEND_PORT): ${YELLOW}✗ Available${NC}"
    fi
    
    # Check API connection
    echo -e "${CYAN}API Connection:${NC}"
    if command -v curl >/dev/null 2>&1; then
        local response=$(curl -s -o /dev/null -w "%{http_code}" -H "Origin: http://localhost:$FRONTEND_PORT" "$STAGING_API_URL/health" 2>/dev/null)
        if [ "$response" = "200" ]; then
            echo -e "  Staging API: ${GREEN}✓ Accessible (HTTP $response)${NC}"
        else
            echo -e "  Staging API: ${RED}✗ Failed (HTTP $response)${NC}"
        fi
    else
        echo -e "  Staging API: ${YELLOW}? Unknown (curl not available)${NC}"
    fi
    
    echo ""
}

# Function to show help
show_help() {
    print_header
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start       Start SSH tunnels for staging development"
    echo "  stop        Stop SSH tunnels"
    echo "  restart     Restart SSH tunnels"
    echo "  status      Show connection status"
    echo "  test        Test all connections"
    echo "  setup       Setup SSH key and test connections"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start    # Start tunnels for development"
    echo "  $0 status   # Check current status"
    echo "  $0 test     # Test all connections"
    echo ""
}

# Function to setup environment
setup_environment() {
    print_header
    print_status "Setting up staging development environment..."
    
    # Check and setup SSH key
    if ! check_ssh_key; then
        return 1
    fi
    
    # Test SSH connection
    if ! test_ssh_connection; then
        return 1
    fi
    
    # Start tunnels
    if ! start_tunnels; then
        return 1
    fi
    
    # Test connections
    if ! test_database_connection; then
        return 1
    fi
    
    if ! test_api_connection; then
        return 1
    fi
    
    print_success "Environment setup complete!"
    echo ""
    print_status "You can now start the frontend with:"
    echo -e "${BLUE}  npm run start:staging${NC}"
    echo ""
    print_status "To stop tunnels when done:"
    echo -e "${BLUE}  $0 stop${NC}"
}

# Function to test all connections
test_connections() {
    print_header
    print_status "Testing all connections..."
    
    local all_tests_passed=true
    
    # Test SSH connection
    if test_ssh_connection; then
        print_success "SSH connection: PASSED"
    else
        print_error "SSH connection: FAILED"
        all_tests_passed=false
    fi
    
    # Test database tunnel
    if test_database_connection; then
        print_success "Database connection: PASSED"
    else
        print_error "Database connection: FAILED"
        all_tests_passed=false
    fi
    
    # Test API connection
    if test_api_connection; then
        print_success "API connection: PASSED"
    else
        print_error "API connection: FAILED"
        all_tests_passed=false
    fi
    
    echo ""
    if $all_tests_passed; then
        print_success "All connection tests passed!"
    else
        print_error "Some connection tests failed"
        return 1
    fi
}

# Main script logic
case "${1:-help}" in
    start)
        print_header
        if check_ssh_key && test_ssh_connection && start_tunnels; then
            print_success "Tunnels started successfully"
            echo ""
            print_status "You can now start the frontend with:"
            echo -e "${BLUE}  npm run start:staging${NC}"
        else
            print_error "Failed to start tunnels"
            exit 1
        fi
        ;;
    stop)
        print_header
        stop_tunnels
        print_success "Tunnels stopped"
        ;;
    restart)
        print_header
        stop_tunnels
        sleep 2
        if start_tunnels; then
            print_success "Tunnels restarted successfully"
        else
            print_error "Failed to restart tunnels"
            exit 1
        fi
        ;;
    status)
        show_status
        ;;
    test)
        test_connections
        ;;
    setup)
        setup_environment
        ;;
    help|*)
        show_help
        ;;
esac
