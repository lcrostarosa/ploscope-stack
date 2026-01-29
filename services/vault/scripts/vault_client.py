#!/usr/bin/env python3
"""
PLO Solver Vault Client
Python client for integrating HashiCorp Vault with the PLO Solver application.
"""

import os
import json
import logging
from typing import Dict, Optional, Any
import hvac
from hvac.exceptions import VaultError

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class PLOSolverVaultClient:
    """Client for interacting with HashiCorp Vault for PLO Solver secrets."""
    
    def __init__(self, vault_addr: Optional[str] = None, token: Optional[str] = None):
        """
        Initialize the Vault client.
        
        Args:
            vault_addr: Vault server address (defaults to VAULT_ADDR env var)
            token: Vault authentication token (defaults to VAULT_TOKEN env var)
        """
        self.vault_addr = vault_addr or os.getenv('VAULT_ADDR', 'http://localhost:8200')
        self.token = token or os.getenv('VAULT_TOKEN')
        
        if not self.token:
            raise ValueError("Vault token is required. Set VAULT_TOKEN environment variable or pass token parameter.")
        
        self.client = hvac.Client(url=self.vault_addr, token=self.token)
        
        # Test connection
        if not self.client.is_authenticated():
            raise VaultError("Failed to authenticate with Vault")
    
    def get_environment_secrets(self, environment: str) -> Dict[str, str]:
        """
        Retrieve all secrets for a specific environment.
        
        Args:
            environment: Environment name (development, staging, production, test)
            
        Returns:
            Dictionary of environment variables
        """
        try:
            secret_path = f"secret/plo-solver/{environment}"
            response = self.client.secrets.kv.v2.read_secret_version(
                path=environment,
                mount_point='secret/plo-solver'
            )
            
            if response and 'data' in response and 'data' in response['data']:
                return response['data']['data']
            else:
                logger.warning(f"No secrets found for environment: {environment}")
                return {}
                
        except VaultError as e:
            logger.error(f"Error retrieving secrets for {environment}: {e}")
            raise
    
    def get_secret(self, environment: str, key: str) -> Optional[str]:
        """
        Retrieve a specific secret for an environment.
        
        Args:
            environment: Environment name
            key: Secret key name
            
        Returns:
            Secret value or None if not found
        """
        secrets = self.get_environment_secrets(environment)
        return secrets.get(key)
    
    def set_secret(self, environment: str, key: str, value: str) -> bool:
        """
        Set a specific secret for an environment.
        
        Args:
            environment: Environment name
            key: Secret key name
            value: Secret value
            
        Returns:
            True if successful, False otherwise
        """
        try:
            # Get existing secrets
            secrets = self.get_environment_secrets(environment)
            secrets[key] = value
            
            # Update secrets
            self.client.secrets.kv.v2.create_or_update_secret(
                path=environment,
                secret=secrets,
                mount_point='secret/plo-solver'
            )
            
            logger.info(f"Successfully set secret {key} for environment {environment}")
            return True
            
        except VaultError as e:
            logger.error(f"Error setting secret {key} for {environment}: {e}")
            return False
    
    def encrypt_value(self, value: str, key_name: str = 'plo-solver-key') -> Optional[str]:
        """
        Encrypt a value using Vault's transit engine.
        
        Args:
            value: Value to encrypt
            key_name: Transit key name
            
        Returns:
            Encrypted value or None if failed
        """
        try:
            response = self.client.secrets.transit.encrypt_data(
                name=key_name,
                plaintext=value
            )
            
            if response and 'data' in response and 'ciphertext' in response['data']:
                return response['data']['ciphertext']
            else:
                logger.error("Invalid response from transit encrypt")
                return None
                
        except VaultError as e:
            logger.error(f"Error encrypting value: {e}")
            return None
    
    def decrypt_value(self, encrypted_value: str, key_name: str = 'plo-solver-key') -> Optional[str]:
        """
        Decrypt a value using Vault's transit engine.
        
        Args:
            encrypted_value: Encrypted value to decrypt
            key_name: Transit key name
            
        Returns:
            Decrypted value or None if failed
        """
        try:
            response = self.client.secrets.transit.decrypt_data(
                name=key_name,
                ciphertext=encrypted_value
            )
            
            if response and 'data' in response and 'plaintext' in response['data']:
                return response['data']['plaintext']
            else:
                logger.error("Invalid response from transit decrypt")
                return None
                
        except VaultError as e:
            logger.error(f"Error decrypting value: {e}")
            return None
    
    def list_environments(self) -> list:
        """
        List all available environments.
        
        Returns:
            List of environment names
        """
        try:
            response = self.client.secrets.kv.v2.list_secrets(
                path='',
                mount_point='secret/plo-solver'
            )
            
            if response and 'data' in response and 'keys' in response['data']:
                return response['data']['keys']
            else:
                return []
                
        except VaultError as e:
            logger.error(f"Error listing environments: {e}")
            return []
    
    def health_check(self) -> bool:
        """
        Check if Vault is healthy and accessible.
        
        Returns:
            True if healthy, False otherwise
        """
        try:
            return self.client.is_initialized() and self.client.is_authenticated()
        except VaultError:
            return False


def load_env_from_vault(environment: str, output_file: Optional[str] = None) -> Dict[str, str]:
    """
    Load environment variables from Vault and optionally write to file.
    
    Args:
        environment: Environment name
        output_file: Optional file path to write environment variables
        
    Returns:
        Dictionary of environment variables
    """
    try:
        client = PLOSolverVaultClient()
        secrets = client.get_environment_secrets(environment)
        
        if output_file:
            with open(output_file, 'w') as f:
                for key, value in secrets.items():
                    f.write(f"{key}={value}\n")
            logger.info(f"Environment variables written to {output_file}")
        
        return secrets
        
    except Exception as e:
        logger.error(f"Error loading environment from Vault: {e}")
        raise


def main():
    """Main function for command-line usage."""
    import argparse
    
    parser = argparse.ArgumentParser(description='PLO Solver Vault Client')
    parser.add_argument('command', choices=['get', 'set', 'list', 'encrypt', 'decrypt', 'load-env'])
    parser.add_argument('--environment', '-e', help='Environment name')
    parser.add_argument('--key', '-k', help='Secret key')
    parser.add_argument('--value', '-v', help='Secret value')
    parser.add_argument('--output', '-o', help='Output file')
    
    args = parser.parse_args()
    
    try:
        client = PLOSolverVaultClient()
        
        if args.command == 'get':
            if not args.environment or not args.key:
                print("Error: environment and key are required for get command")
                return
            value = client.get_secret(args.environment, args.key)
            print(value if value else "Secret not found")
            
        elif args.command == 'set':
            if not args.environment or not args.key or not args.value:
                print("Error: environment, key, and value are required for set command")
                return
            success = client.set_secret(args.environment, args.key, args.value)
            print("Success" if success else "Failed")
            
        elif args.command == 'list':
            environments = client.list_environments()
            print("Available environments:")
            for env in environments:
                print(f"  {env}")
                
        elif args.command == 'encrypt':
            if not args.value:
                print("Error: value is required for encrypt command")
                return
            encrypted = client.encrypt_value(args.value)
            print(encrypted if encrypted else "Encryption failed")
            
        elif args.command == 'decrypt':
            if not args.value:
                print("Error: value is required for decrypt command")
                return
            decrypted = client.decrypt_value(args.value)
            print(decrypted if decrypted else "Decryption failed")
            
        elif args.command == 'load-env':
            if not args.environment:
                print("Error: environment is required for load-env command")
                return
            secrets = load_env_from_vault(args.environment, args.output)
            if not args.output:
                for key, value in secrets.items():
                    print(f"{key}={value}")
                    
    except Exception as e:
        print(f"Error: {e}")
        return 1
    
    return 0


if __name__ == '__main__':
    exit(main()) 