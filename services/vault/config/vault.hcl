# Vault Configuration for PLO Solver
# This configuration is for development use
# For production, use proper storage backend and TLS

storage "file" {
  path = "/vault/file"
}

# HTTP listener
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1  # Disable TLS for development
}

# API configuration
api_addr = "http://0.0.0.0:8200"
cluster_addr = "https://0.0.0.0:8201"

# UI configuration
ui = true

# Disable mlock for development
disable_mlock = true

# Logging
log_level = "INFO"

# Default lease TTL
default_lease_ttl = "24h"
max_lease_ttl = "8760h"

# Enable audit logging
audit "file" {
  file_path = "/vault/logs/audit.log"
  log_raw = false
  format = "json"
} 