# PLO Solver Forum Integration - Complete Setup Guide

This guide will help you set up a complete forum integration using [Discourse Docker](https://github.com/discourse/discourse_docker), Traefik, Ngrok, and npm with comprehensive testing.

## 🎯 What You'll Get

- **Self-hosted Discourse forum** integrated with PLO Solver
- **Single Sign-On (SSO)** between PLO Solver and Discourse
- **Traefik reverse proxy** for routing
- **Ngrok tunneling** for external access
- **Comprehensive testing** including E2E tests
- **Docker containerization** for easy deployment

## 📋 Prerequisites

### Required Software
- **Docker** and Docker Compose
- **Node.js** (v16 or later) and npm
- **Traefik** (v2.10+)
- **Ngrok** account and CLI
- **Git**

### System Requirements
- **8GB RAM minimum** (Discourse is memory-intensive)
- **20GB free disk space**
- **Unix-like system** (macOS, Linux, WSL2)

## 🚀 Quick Start

### 1. Install Dependencies

```bash
# Install Node.js dependencies
npm install

# Install Puppeteer for E2E testing
npm install puppeteer

# Install Traefik (macOS)
brew install traefik

# Install Traefik (Linux)
wget https://github.com/traefik/traefik/releases/download/v2.10.7/traefik_v2.10.7_linux_amd64.tar.gz
tar -zxvf traefik_v2.10.7_linux_amd64.tar.gz
sudo mv traefik /usr/local/bin/
```

### 2. Configure Environment

```bash
# Copy environment template
cp env.example .env

# Edit the environment file
nano .env
```

**Required Environment Variables:**
```bash
# Basic Configuration
FRONTEND_DOMAIN=localhost
DISCOURSE_DOMAIN=forum.localhost

# Generate a secure SSO secret (32+ characters)
DISCOURSE_SSO_SECRET=$(openssl rand -hex 32)

# Database credentials
DISCOURSE_DB_PASSWORD=secure_password_here
POSTGRES_PASSWORD=secure_password_here

# Admin email
DISCOURSE_DEVELOPER_EMAILS=admin@plosolver.local
```

### 3. Set Up Discourse

```bash
# Run the automated setup
npm run setup:discourse

# Or manually:
./setup-discourse.sh
```

This script will:
- Generate SSO secrets if needed
- Create required directories with proper permissions
- Configure Discourse with your settings
- Bootstrap the Discourse container (takes 10-15 minutes)

### 4. Start Services

```bash
# Start Docker services
docker compose up -d

# Verify services are running
docker compose ps
```

### 5. Set Up Ngrok Tunneling

```bash
# Terminal 1 - Main app tunnel
ngrok http 80

# Terminal 2 - Forum tunnel (if using dual tunnel mode)
ngrok http 8080

# Terminal 3 - Start with forum support
./start-ngrok-with-forum.sh <app-ngrok-url> <forum-ngrok-url>

# Or single tunnel mode:
./start-ngrok-with-forum.sh <ngrok-url> same
```

## 🧪 Testing

### Unit Tests
```bash
# Run all tests
npm test

# Run forum-specific tests
npm run test:forum

# Run with coverage
npm run test:coverage
```

### End-to-End Tests
```bash
# Interactive E2E test (shows browser)
npm run test:e2e

# Headless E2E test (faster)
npm run test:e2e:headless

# Slow motion E2E test (for demonstration)
npm run test:e2e:slow
```

### Manual Testing Checklist

1. **User Registration/Login**
   - [ ] Go to your ngrok URL
   - [ ] Click "Sign Up / Login"
   - [ ] Register a new account
   - [ ] Verify email functionality (if SMTP configured)
   - [ ] Log in successfully

2. **Forum Access**
   - [ ] Click the "💬 Forum" tab
   - [ ] See welcome message with your name
   - [ ] Click "🚀 Access Forum"
   - [ ] Get redirected to Discourse in new tab
   - [ ] Verify automatic login to Discourse

3. **SSO Integration**
   - [ ] User profile data synced (name, email, username)
   - [ ] No double login required
   - [ ] Logout from PLO Solver affects forum access

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│     Ngrok       │────│     Traefik     │────│   PLO Solver    │
│   (External)    │    │  (Reverse Proxy)│    │   (Frontend)    │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                        │
                                │                        │
                       ┌─────────────────┐    ┌─────────────────┐
                       │                 │    │                 │
                       │   Discourse     │────│   PLO Solver    │
                       │    (Forum)      │    │   (Backend)     │
                       │                 │    │                 │
                       └─────────────────┘    └─────────────────┘
                                │                        │
                                │                        │
                       ┌─────────────────┐    ┌─────────────────┐
                       │                 │    │                 │
                       │ Discourse Redis │    │   PostgreSQL    │
                       │ Discourse PG    │    │   (Main DB)     │
                       │                 │    │                 │
                       └─────────────────┘    └─────────────────┘
```

## 🔧 Configuration Details

### Traefik Configuration

The setup creates dynamic Traefik configurations for:
- **Frontend routing**: Routes main app traffic
- **API routing**: Routes `/api/*` to backend
- **Forum routing**: Routes forum traffic to Discourse
- **CORS headers**: Enables cross-origin requests
- **SSL termination**: Handles HTTPS certificates

### Discourse Configuration

Located in `discourse/containers/app.yml`:
- **SSO Settings**: Enables SSO provider mode
- **Database**: Separate PostgreSQL instance
- **Redis**: Dedicated Redis for Discourse
- **Email**: SMTP configuration (optional)
- **Plugins**: Docker Manager for updates

### Docker Services

The `docker compose.yml` includes:
- **PLO Solver Frontend**: React app
- **PLO Solver Backend**: Flask API
- **Discourse**: Forum application  
- **Discourse Database**: PostgreSQL
- **Discourse Redis**: Redis cache
- **Main Database**: PostgreSQL for PLO Solver
- **Traefik**: Reverse proxy

## 🚨 Troubleshooting

### Common Issues

**"Forum integration not configured"**
```bash
# Check environment variables
echo $DISCOURSE_SSO_SECRET
source .env

# Restart backend
docker compose restart backend
```

**Discourse won't start**
```bash
# Check logs
docker compose logs discourse

# Check disk space (Discourse needs 2GB+)
df -h

# Check memory (Discourse needs 1GB+ RAM)
free -h
```

**SSO redirect loops**
```bash
# Verify URLs match
echo "App URL: $FRONTEND_DOMAIN"
echo "Forum URL: $DISCOURSE_DOMAIN"

# Check Discourse admin settings
# Go to forum.yourngrok.com/admin/settings/login
```

**Ngrok connection refused**
```bash
# Check if ports are available
netstat -tulpn | grep :80
netstat -tulpn | grep :8080

# Restart Traefik
pkill traefik
traefik --configfile=traefik-ngrok-forum.yml &
```

### Debug Commands

```bash
# Check all services
docker compose ps

# View logs
docker compose logs -f discourse
docker compose logs -f backend

# Test API endpoints
curl http://localhost/api/health
curl http://localhost/api/discourse/sso -H "Authorization: Bearer YOUR_TOKEN"

# Test Discourse directly
curl http://localhost:8080

# Check Traefik routing
curl http://localhost:8080/dashboard/
```

### Performance Optimization

**Discourse Memory Usage:**
```bash
# Monitor memory usage
docker stats discourse

# Adjust worker count in app.yml
UNICORN_WORKERS: 2  # Reduce if low memory
```

**Database Performance:**
```bash
# Optimize PostgreSQL
# Add to docker compose.yml:
command: postgres -c shared_buffers=256MB -c effective_cache_size=1GB
```

## 📊 Monitoring

### Health Checks

```bash
# Application health
curl http://localhost/health

# Database health  
docker compose exec db pg_isready

# Discourse health
curl http://localhost:8080/srv/status
```

### Log Aggregation

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f discourse

# Follow new logs
docker compose logs -f --tail=100
```

### Metrics Collection

The setup includes:
- **Traefik metrics**: Access logs and performance
- **Discourse metrics**: Built-in admin metrics
- **Docker metrics**: Container resource usage

## 🔒 Security

### Production Considerations

1. **SSL/TLS**: Use real certificates (Let's Encrypt)
2. **Secrets**: Use Docker secrets or external secret management
3. **Firewall**: Restrict database access
4. **Updates**: Regular security updates for all components
5. **Backup**: Automated database and file backups

### Security Headers

Traefik automatically adds:
- CORS headers for API access
- Security headers for HTTPS
- Rate limiting (configurable)

## 📈 Scaling

### Horizontal Scaling

```yaml
# Add to docker compose.yml for multiple forum instances
discourse-2:
  image: discourse/base:2.0.20240102-0014
  # ... same config as discourse
```

### Load Balancing

```yaml
# Traefik automatically load balances multiple instances
services:
  discourse:
    deploy:
      replicas: 2
```

### Database Scaling

- **Read Replicas**: Configure PostgreSQL read replicas
- **Connection Pooling**: Use PgBouncer for connection pooling
- **Caching**: Redis cluster for distributed caching

## 📚 Additional Resources

- [Discourse Docker Documentation](https://github.com/discourse/discourse_docker)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Ngrok Documentation](https://ngrok.com/docs)
- [Docker Compose Reference](https://docs.docker.com/compose/)

## 🆘 Support

For issues specific to this integration:

1. **Check logs**: Start with Docker and Traefik logs
2. **Verify configuration**: Ensure all environment variables are set
3. **Test components**: Isolate issues to specific services
4. **Community help**: Discourse and PLO Solver communities

---

## 🎉 Success Checklist

- [ ] All Docker services running (`docker compose ps`)
- [ ] Traefik dashboard accessible (`http://localhost:8080`)
- [ ] Main app accessible via Ngrok URL
- [ ] Forum accessible via forum Ngrok URL
- [ ] User can register/login to PLO Solver
- [ ] Forum tab appears after login
- [ ] SSO redirect works (opens forum in new tab)
- [ ] User automatically logged into Discourse
- [ ] User can post in forum
- [ ] Logout from PLO Solver affects forum access
- [ ] E2E tests pass (`npm run test:e2e`)

**🎊 Congratulations! Your PLO Solver Forum integration is complete!** 