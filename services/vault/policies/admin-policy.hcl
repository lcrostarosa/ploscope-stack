# Admin policy for PLO Solver secrets management
# This policy allows full CRUD operations on plo-solver secrets only

# Full access to plo-solver secrets
path "secret/data/plo-solver/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/metadata/plo-solver/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Allow admin to manage policies
path "sys/policies/acl/container-readonly" {
  capabilities = ["read"]
}

path "sys/policies/acl/admin-policy" {
  capabilities = ["read"]
}

# Allow admin to create and manage tokens
path "auth/token/create" {
  capabilities = ["create", "update"]
}

path "auth/token/lookup" {
  capabilities = ["read"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# Allow admin to list mounts and policies
path "sys/mounts" {
  capabilities = ["read"]
}

path "sys/policies/acl" {
  capabilities = ["list"]
}

# Deny access to system secrets and other namespaces
path "secret/data/*" {
  capabilities = ["deny"]
}

path "sys/*" {
  capabilities = ["deny"]
} 