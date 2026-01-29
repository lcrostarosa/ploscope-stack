# PLO Solver Write Policy
# This policy grants write access for loading secrets into Vault
# Use this policy for operations that need to write secrets

# Allow writing secrets to plo-solver paths
path "secret/data/plo-solver/*" {
  capabilities = ["create", "update"]
}

# Allow reading secrets from plo-solver paths
path "secret/data/plo-solver/*" {
  capabilities = ["read"]
}

# Allow reading metadata
path "secret/metadata/plo-solver/*" {
  capabilities = ["read"]
}

# Allow listing of secret paths
path "secret/metadata/plo-solver/" {
  capabilities = ["list"]
}

# Allow reading transit keys for encryption/decryption
path "transit/keys/plo-solver-*" {
  capabilities = ["read"]
}

path "transit/encrypt/plo-solver-*" {
  capabilities = ["create", "update"]
}

path "transit/decrypt/plo-solver-*" {
  capabilities = ["create", "update"]
}

# Allow reading auth token info
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
} 