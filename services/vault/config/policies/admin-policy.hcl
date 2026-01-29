# Admin Policy for PLO Solver Vault Management
# This policy grants full access for administrative tasks

# Full access to all secrets
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Full access to policies
path "sys/policies/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Full access to auth methods
path "sys/auth/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Full access to mounts
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Full access to tokens
path "auth/token/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Full access to transit engine
path "transit/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# System information
path "sys/health" {
  capabilities = ["read"]
}

path "sys/leader" {
  capabilities = ["read"]
}

path "sys/metrics" {
  capabilities = ["read"]
}

# Audit logging
path "sys/audit/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Key management
path "sys/key-status" {
  capabilities = ["read"]
}

path "sys/rotate" {
  capabilities = ["update"]
} 