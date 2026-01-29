# Read-only policy for containers
# This policy only allows read operations on secrets

path "secret/data/plo-solver/*" {
  capabilities = ["read"]
}

path "secret/metadata/plo-solver/*" {
  capabilities = ["read"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "sys/mounts" {
  capabilities = ["read"]
}

# Deny all other operations
path "*" {
  capabilities = ["deny"]
} 