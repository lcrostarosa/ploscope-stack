# Scripts Directory

This directory contains various scripts organized by purpose and lifecycle stage.

## Directory Structure

**Total Files Organized: 85+ scripts and configuration files**

### `/setup` (24 files)
Scripts for initial system setup, environment configuration, and first-time installation tasks.
- Database initialization
- SSL certificate setup  
- Service configuration
- Environment preparation
- GitHub setup and CI configuration
- OpenVPN and security setup

### `/testing` (22 files)
Scripts for automated testing, validation, and quality assurance.
- Unit test runners
- Integration test scripts
- Load testing
- Validation scripts
- Test environment configurations

### `/development` (11 files)
Scripts to aid in local development and debugging.
- Development environment setup
- Debug helpers
- Ngrok tunnels for local development
- ELK stack management
- Local service runners

### `/deployment` (4 files)
Scripts for deploying the application to various environments.
- Production deployment
- Staging deployment
- Environment-specific configurations
- Release automation

### `/ci` (6 files)
Continuous Integration and Continuous Deployment scripts.
- Build scripts
- Test automation
- Pipeline configurations
- CI variables and secrets management

### `/docs` (3 files)
Scripts for generating and maintaining documentation.
- API documentation generators
- React documentation generators  
- Documentation build and serving scripts

### `/operations` (10 files)
Scripts for ongoing system operations and maintenance.
- Certificate management and monitoring
- Health checks and system monitoring
- Log rotation configuration
- Security checks
- Service restart and management

### `/utilities` (5 files)
General-purpose utility scripts that can be used across different contexts.
- Helper functions
- SSH tunnel management
- Environment switching
- Entrypoint wrappers for containers

## Usage

Each directory contains scripts specific to its purpose. Scripts should be:
- Executable (`chmod +x`)
- Well-documented with comments
- Include error handling
- Follow consistent naming conventions

## Naming Conventions

- Use kebab-case for script names: `setup-database.sh`
- Include the purpose in the name: `test-api-endpoints.sh`
- Use descriptive names that explain what the script does