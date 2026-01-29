# Forum Integration Guide

The `run_with_traefik.sh` script now supports optional Discourse forum integration.

## Usage

### Start with Forum
```bash
./run_with_traefik.sh --forum
```

### Start without Forum (default)
```bash
./run_with_traefik.sh
```

## What Gets Started

### Without Forum (Default)
- ✅ Traefik (reverse proxy on port 80)
- ✅ PostgreSQL (database on port 5432)
- ✅ Backend Flask API (port 5001)
- ✅ React Frontend (port 3000)

### With Forum (`--forum` option)
- ✅ All of the above, plus:
- ✅ Discourse Forum (Docker container on port 4080)
- ✅ Forum routing via Traefik

## Access Points

### Basic Setup
- **Frontend**: http://localhost
- **API**: http://localhost/api  
- **Traefik Dashboard**: http://localhost:8080

### With Forum
- **Frontend**: http://localhost
- **API**: http://localhost/api
- **Forum**: http://localhost/forum OR http://forum.localhost
- **Forum Direct**: http://localhost:4080
- **Traefik Dashboard**: http://localhost:8080

## Requirements

### For Basic Setup
- Traefik (`brew install traefik`)
- PostgreSQL (local or Docker)
- Node.js and npm
- Python 3.x

### Additional for Forum
- Docker (required for Discourse)
- ~2GB disk space for Discourse image
- Additional ~512MB RAM for forum container

## Forum Features

### SSO Integration
- Single Sign-On with PLO Solver accounts
- Automatic user creation and login
- Synchronized user profiles

### Access Control
- Forum posts linked to PLO Solver users
- Consistent authentication across platform
- Role-based permissions (future)

### Routing
- `/forum` path routes to Discourse
- `forum.localhost` subdomain support
- Direct access via port 4080

## Configuration

The script uses these default forum settings:
```bash
FORUM_DOMAIN="forum.localhost"
FORUM_PORT="4080"
DISCOURSE_VERSION="2.0.20241202-1135"
DISCOURSE_SSO_SECRET="36241cd9e33f8dbe7d768ff97164bc181a9070f0fc5bcc4e91ba5fef998b39c0"
```

These can be modified in the script if needed.

## Traefik Routing

When forum is enabled, the script automatically updates `dynamic.yml` to include:

```yaml
forum:
  rule: "Host(`forum.localhost`) || PathPrefix(`/forum`)"
  priority: 7
  service: forum
```

This allows both subdomain and path-based access to the forum.

## Troubleshooting

### Forum Container Issues
```bash
# Check if container is running
docker ps | grep plosolver-discourse

# Check container logs
docker logs plosolver-discourse

# Restart forum container
docker rm -f plosolver-discourse
./run_with_traefik.sh --forum
```

### Forum Not Accessible
1. Wait 2-3 minutes for Discourse to fully start
2. Check http://localhost:4080 for direct access
3. Verify Docker is running: `docker --version`
4. Check Traefik dashboard: http://localhost:8080

### SSO Issues
- Ensure backend is running and accessible
- Verify SSO endpoint: http://localhost/api/discourse/sso_provider
- Check forum admin settings for SSO configuration

## Performance Notes

- Forum startup takes 2-3 minutes on first run
- Subsequent starts are faster (~30 seconds)
- Forum uses ~512MB RAM when running
- Database is shared between PLO Solver and forum

## Stopping Services

Use `Ctrl+C` to stop all services. The script will automatically:
- Stop Traefik, backend, and frontend
- Stop PostgreSQL (if started by script)
- Stop and remove forum Docker container
- Clean up all processes and containers 