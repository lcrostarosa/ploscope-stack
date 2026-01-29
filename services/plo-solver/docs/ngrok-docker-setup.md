# ngrok + Docker Setup Guide

This guide explains how to run PLOSolver with ngrok tunneling and Docker containers for external access.

## Prerequisites

1. **Docker Desktop** - Must be running
2. **ngrok** - Install with `brew install ngrok`
3. **ngrok Authentication** - Get your authtoken from [ngrok dashboard](https://dashboard.ngrok.com/get-started/your-authtoken)
4. **jq** (for simple version) - Install with `brew install jq`

## Setup ngrok Authentication

```bash
# Get your authtoken from https://dashboard.ngrok.com/get-started/your-authtoken
ngrok config add-authtoken YOUR_AUTHTOKEN_HERE
```

## Available Commands

### 1. Manual ngrok + Docker
Requires you to provide the ngrok URL manually:

```bash
# Start ngrok in another terminal first
ngrok http 80

# Then use the URL with Docker
NGROK_URL=https://abc123.ngrok-free.app make ngrok-docker
# OR
make ngrok-docker NGROK_URL=https://abc123.ngrok-free.app
```

### 2. Automatic ngrok + Docker (Recommended)
Automatically starts ngrok and Docker together:

```bash
# Basic setup
make ngrok-auto

# With forum support
make ngrok-auto-forum

# Rebuild images first
make ngrok-auto-rebuild
```

### 3. Simple ngrok + Docker
Uses jq for JSON parsing (more reliable):

```bash
make ngrok-simple
```

## What Happens

1. **ngrok tunnel** is started on port 80
2. **ngrok URL** is automatically extracted
3. **Docker containers** are started with ngrok configuration:
   - Frontend accessible via ngrok URL
   - Backend API accessible via ngrok URL + `/api`
   - All CORS and routing configured automatically

## Access Points

Once running, you can access:

- **Local Frontend**: http://localhost
- **ngrok Frontend**: https://your-ngrok-url.ngrok-free.app
- **Local API**: http://localhost/api
- **ngrok API**: https://your-ngrok-url.ngrok-free.app/api
- **Traefik Dashboard**: http://localhost:8080
- **RabbitMQ Management**: http://localhost:15672
- **ngrok Dashboard**: http://localhost:4040

## Environment Variables

The ngrok + Docker setup automatically configures:

```bash
FRONTEND_DOMAIN=your-ngrok-domain.ngrok-free.app
TRAEFIK_DOMAIN=your-ngrok-domain.ngrok-free.app
REACT_APP_API_URL=/api
```

## Stopping Services

Press `Ctrl+C` in the terminal running the command, or run:

```bash
# Stop Docker containers
docker compose down

# Kill ngrok process (if running separately)
pkill ngrok
```

## Troubleshooting

### ngrok Authentication Error
```bash
# Check authentication
ngrok config check

# Re-authenticate
ngrok config add-authtoken YOUR_AUTHTOKEN_HERE
```

### Port Already in Use
```bash
# Kill processes on port 80
sudo lsof -ti:80 | xargs kill -9

# Or use a different port
./scripts/development/ngrok-docker-simple.sh --port 8080
```

### Docker Not Running
```bash
# Start Docker Desktop
open -a Docker

# Wait for Docker to be ready
docker info
```

### Can't Get ngrok URL
```bash
# Check ngrok API manually
curl http://localhost:4040/api/tunnels

# Check ngrok logs
tail -f /tmp/ngrok.log
```

## Security Notes

- ngrok URLs are publicly accessible
- Use ngrok's authentication features for production
- Consider ngrok's paid plans for custom domains
- Monitor access logs via ngrok dashboard

## Examples

### Basic Development
```bash
make ngrok-auto
```

### Development with Forum
```bash
make ngrok-auto-forum
```

### Fresh Build with ngrok
```bash
make ngrok-auto-rebuild
```

### Manual Control
```bash
# Terminal 1: Start ngrok
ngrok http 80

# Terminal 2: Get the URL and start Docker
NGROK_URL=https://abc123.ngrok-free.app make ngrok-docker
``` 