#!/bin/bash

# Elasticsearch Password Manager
# This script manages passwords for Elasticsearch users

set -e

ELASTIC_PASSWORD=${ELASTIC_PASSWORD:-changeme}
ELASTICSEARCH_HOST=${ELASTICSEARCH_HOST:-localhost:9200}

# Function to change password for a user
change_user_password() {
    local username=$1
    local new_password=$2
    
    echo "Changing password for user: $username"
    
    curl -X POST -u elastic:${ELASTIC_PASSWORD} \
        "http://${ELASTICSEARCH_HOST}/_security/user/${username}/_password" \
        -H "Content-Type: application/json" \
        -d "{\"password\":\"${new_password}\"}"
    
    echo "Password changed successfully for user: $username"
}

# Function to list all users
list_users() {
    echo "Listing all users:"
    curl -s -u elastic:${ELASTIC_PASSWORD} \
        "http://${ELASTICSEARCH_HOST}/_security/user" | jq .
}

# Function to create a new user
create_user() {
    local username=$1
    local password=$2
    local roles=$3
    
    echo "Creating user: $username with roles: $roles"
    
    curl -X POST -u elastic:${ELASTIC_PASSWORD} \
        "http://${ELASTICSEARCH_HOST}/_security/user/${username}" \
        -H "Content-Type: application/json" \
        -d "{
            \"password\": \"${password}\",
            \"roles\": [${roles}],
            \"full_name\": \"${username} user\",
            \"email\": \"${username}@plosolver.com\"
        }"
    
    echo "User created successfully: $username"
}

# Function to delete a user
delete_user() {
    local username=$1
    
    echo "Deleting user: $username"
    
    curl -X DELETE -u elastic:${ELASTIC_PASSWORD} \
        "http://${ELASTICSEARCH_HOST}/_security/user/${username}"
    
    echo "User deleted successfully: $username"
}

# Main script logic
case "${1:-help}" in
    "change-password")
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: $0 change-password <username> <new_password>"
            exit 1
        fi
        change_user_password "$2" "$3"
        ;;
    "list-users")
        list_users
        ;;
    "create-user")
        if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
            echo "Usage: $0 create-user <username> <password> <roles>"
            echo "Example: $0 create-user myuser mypass '\"kibana_user\",\"logstash_writer\"'"
            exit 1
        fi
        create_user "$2" "$3" "$4"
        ;;
    "delete-user")
        if [ -z "$2" ]; then
            echo "Usage: $0 delete-user <username>"
            exit 1
        fi
        delete_user "$2"
        ;;
    "setup-default-users")
        echo "Setting up default users for ELK stack..."
        
        # Change kibana_system password
        change_user_password "kibana_system" "${ELASTIC_PASSWORD}"
        
        # Create logstash_writer user if it doesn't exist
        echo "Creating logstash_writer user..."
        curl -X POST -u elastic:${ELASTIC_PASSWORD} \
            "http://${ELASTICSEARCH_HOST}/_security/user/logstash_writer" \
            -H "Content-Type: application/json" \
            -d "{
                \"password\": \"${ELASTIC_PASSWORD}\",
                \"roles\": [\"logstash_writer\"],
                \"full_name\": \"Logstash Writer\",
                \"email\": \"logstash@plosolver.com\"
            }" 2>/dev/null || echo "logstash_writer user already exists"
        
        # Create beats_writer user if it doesn't exist
        echo "Creating beats_writer user..."
        curl -X POST -u elastic:${ELASTIC_PASSWORD} \
            "http://${ELASTICSEARCH_HOST}/_security/user/beats_writer" \
            -H "Content-Type: application/json" \
            -d "{
                \"password\": \"${ELASTIC_PASSWORD}\",
                \"roles\": [\"beats_writer\"],
                \"full_name\": \"Beats Writer\",
                \"email\": \"beats@plosolver.com\"
            }" 2>/dev/null || echo "beats_writer user already exists"
        
        echo "Default users setup complete!"
        ;;
    *)
        echo "Elasticsearch Password Manager"
        echo ""
        echo "Usage:"
        echo "  $0 change-password <username> <new_password>  - Change user password"
        echo "  $0 list-users                                 - List all users"
        echo "  $0 create-user <username> <password> <roles>  - Create new user"
        echo "  $0 delete-user <username>                     - Delete user"
        echo "  $0 setup-default-users                        - Setup default ELK users"
        echo ""
        echo "Environment variables:"
        echo "  ELASTIC_PASSWORD     - Elasticsearch admin password (default: changeme)"
        echo "  ELASTICSEARCH_HOST   - Elasticsearch host (default: localhost:9200)"
        ;;
esac 