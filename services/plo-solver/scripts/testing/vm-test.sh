#!/bin/bash

# PLOSolver Test VM Management Script
# This script helps manage the headless Ubuntu VM for testing

set -e

VM_NAME="plosolver-test"
VM_IP="192.168.56.10"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if Vagrant is installed
check_vagrant() {
    if ! command -v vagrant &> /dev/null; then
        print_error "Vagrant is not installed. Please install Vagrant first."
        echo "Download from: https://www.vagrantup.com/downloads"
        exit 1
    fi
    print_success "Vagrant is installed"
}

# Check if VirtualBox is installed
check_virtualbox() {
    if ! command -v VBoxManage &> /dev/null; then
        print_error "VirtualBox is not installed. Please install VirtualBox first."
        echo "Download from: https://www.virtualbox.org/wiki/Downloads"
        exit 1
    fi
    print_success "VirtualBox is installed"
}

# Start the VM
start_vm() {
    print_status "Starting PLOSolver test VM..."
    vagrant up
    print_success "VM started successfully"
    print_status "VM IP: $VM_IP"
    print_status "SSH: vagrant ssh"
}

# Stop the VM
stop_vm() {
    print_status "Stopping PLOSolver test VM..."
    vagrant halt
    print_success "VM stopped successfully"
}

# Destroy the VM
destroy_vm() {
    print_warning "This will completely destroy the VM and all data!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Destroying PLOSolver test VM..."
        vagrant destroy -f
        print_success "VM destroyed successfully"
    else
        print_status "Operation cancelled"
    fi
}

# SSH into the VM
ssh_vm() {
    print_status "Connecting to VM via SSH..."
    vagrant ssh
}

# Run tests in the VM
run_tests() {
    print_status "Running tests in VM..."
    vagrant ssh -c "cd /vagrant && ./scripts/setup/setup-dependencies.sh"
    vagrant ssh -c "cd /vagrant && make test"
}

# Run Docker tests in the VM
run_docker_tests() {
    print_status "Running Docker tests in VM..."
    vagrant ssh -c "cd /vagrant && make run-docker"
}

# Check VM status
status_vm() {
    print_status "Checking VM status..."
    vagrant status
}

# Copy files to VM
copy_to_vm() {
    if [ -z "$1" ]; then
        print_error "Please specify a file or directory to copy"
        exit 1
    fi
    print_status "Copying $1 to VM..."
    vagrant rsync
    print_success "Files synced to VM"
}

# Run a command in the VM
run_in_vm() {
    if [ -z "$1" ]; then
        print_error "Please specify a command to run"
        exit 1
    fi
    print_status "Running command in VM: $1"
    vagrant ssh -c "$1"
}

# Show VM logs
show_logs() {
    print_status "Showing VM logs..."
    vagrant ssh -c "journalctl -f"
}

# Main function
main() {
    case "${1:-help}" in
        "start")
            check_vagrant
            check_virtualbox
            start_vm
            ;;
        "stop")
            stop_vm
            ;;
        "restart")
            stop_vm
            start_vm
            ;;
        "destroy")
            destroy_vm
            ;;
        "ssh")
            ssh_vm
            ;;
        "test")
            run_tests
            ;;
        "docker-test")
            run_docker_tests
            ;;
        "status")
            status_vm
            ;;
        "copy")
            copy_to_vm "$2"
            ;;
        "run")
            run_in_vm "$2"
            ;;
        "logs")
            show_logs
            ;;
        "setup")
            check_vagrant
            check_virtualbox
            print_status "Setting up PLOSolver test environment..."
            vagrant up --provision
            print_success "Setup complete!"
            print_status "VM IP: $VM_IP"
            print_status "SSH: vagrant ssh"
            ;;
        "help"|*)
            echo "PLOSolver Test VM Management Script"
            echo ""
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  setup      - Set up the test environment (first time)"
            echo "  start      - Start the VM"
            echo "  stop       - Stop the VM"
            echo "  restart    - Restart the VM"
            echo "  destroy    - Destroy the VM completely"
            echo "  ssh        - SSH into the VM"
            echo "  test       - Run tests in the VM"
            echo "  docker-test - Run Docker tests in the VM"
            echo "  status     - Show VM status"
            echo "  copy       - Sync files to VM"
            echo "  run <cmd>  - Run a command in the VM"
            echo "  logs       - Show VM logs"
            echo "  help       - Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 setup"
            echo "  $0 start"
            echo "  $0 ssh"
            echo "  $0 run 'cd /vagrant && make test'"
            ;;
    esac
}

# Run main function
main "$@" 