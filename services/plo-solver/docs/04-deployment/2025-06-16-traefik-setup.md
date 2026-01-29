# PLO Solver - Traefik Setup Guide

This guide explains how to run PLO Solver with Traefik reverse proxy for both development and production environments.

## 🚀 Quick Start

### Development Setup

1. **Copy the environment file:**
   ```bash
   cp env.example .env
   ```

2. **Edit the `.env` file** with your configuration:
   ```bash
   # Basic development setup
   FRONTEND_DOMAIN=localhost
   REACT_APP_API_URL=/api
   ```

3. **Start the services:**
   ```bash
   docker compose up -d
   ```

4. **Access your application:**
   - **App:** http://localhost
   - **Traefik Dashboard:** http://localhost:8080

### Production Setup

1. **Copy and configure environment:**
   ```bash
   cp env.example .env
   ```

2. **Edit `.env` for production:**
   ```bash
   FRONTEND_DOMAIN=plosolver.yourdomain.com
   ACME_EMAIL=your-email@yourdomain.com
   NODE_ENV=production
   FLASK_DEBUG=false
   SECRET_KEY=your-super-secure-secret-key
   POSTGRES_PASSWORD=your-secure-database-password
   ```

3. **Start with production configuration:**
   ```bash
   docker compose -f docker-compose.yml -f docker compose.prod.yml up -d
   ```

## 🔧 Configuration Options

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `FRONTEND_DOMAIN` | Domain for your app | `localhost` | Yes |
| `ACME_EMAIL` | Email for Let's Encrypt | `admin@example.com` | Production |
| `TRAEFIK_LOG_LEVEL` | Traefik log level | `INFO` | No |
| `NODE_ENV` | Node environment | `development` | No |
| `FLASK_DEBUG` | Flask debug mode | `true` | No |
| `REACT_APP_API_URL` | API URL for frontend | `/api` | No |
| `SECRET_KEY` | Flask secret key | `dev-secret-key...` | Production |
| `POSTGRES_PASSWORD` | Database password | `postgres` | Production |

### Traefik Features Enabled

- ✅ **Automatic HTTPS** with Let's Encrypt
- ✅ **HTTP to HTTPS redirect** (automatic for all domains)
- ✅ **ACME challenge support** (HTTP access for Let's Encrypt validation)
- ✅ **CORS headers** for API requests
- ✅ **Load balancing** ready
- ✅ **Health checks** for all services
- ✅ **Access logs** and monitoring
- ✅ **Security headers**

## 🌐 Domain Configuration

### Development (localhost)
```bash
FRONTEND_DOMAIN=localhost
```
Access: http://localhost

### Production (custom domain)
```bash
FRONTEND_DOMAIN=plosolver.yourdomain.com
ACME_EMAIL=your-email@yourdomain.com
```
Access: https://plosolver.yourdomain.com

### Subdomain Setup
```bash
FRONTEND_DOMAIN=app.yourdomain.com
```
Access: https://app.yourdomain.com

## 🔒 HTTPS & SSL

### Automatic SSL (Production)
Traefik automatically obtains SSL certificates from Let's Encrypt when:
- `FRONTEND_DOMAIN` is set to a real domain
- `ACME_EMAIL` is configured
- Domain points to your server

### Development SSL (Optional)
For local HTTPS development, you can use mkcert:
```bash
# Install mkcert
brew install mkcert  # macOS
# or
sudo apt install mkcert  # Ubuntu

# Create local CA
mkcert -install

# Generate certificates
mkcert localhost 127.0.0.1 ::1
```

## 📊 Monitoring & Debugging

### Traefik Dashboard
- **Development:** http://localhost:8080
- **Production:** Disabled for security

### Logs
```bash
# View all logs
docker compose logs -f

# View specific service logs
docker compose logs -f traefik
docker compose logs -f frontend
docker compose logs -f backend
```

### Health Checks
```bash
# Check service health
docker compose ps

# Test endpoints
curl http://localhost/health  # Frontend health
curl http://localhost/api/health  # Backend health
```

### Testing HTTPS Redirects
```bash
# Test that HTTP requests redirect to HTTPS
./scripts/development/test-https-redirects.sh

# Manual test examples
curl -I http://localhost  # Should return 301/302 redirect to https://localhost
curl -I http://localhost/api/health  # Should redirect to https://localhost/api/health

# Test ACME challenges (should NOT redirect)
curl -I http://localhost/.well-known/acme-challenge/test  # Should return 404, not redirect
```

## 🚀 Deployment Scenarios

### 1. Local Development
```bash
# Standard development
docker compose up -d

# With custom domain (add to /etc/hosts)
echo "127.0.0.1 plo.local" >> /etc/hosts
FRONTEND_DOMAIN=plo.local docker compose up -d
```

### 2. VPS/Cloud Server
```bash
# Point your domain to server IP
# Configure DNS: A record plosolver.yourdomain.com -> YOUR_SERVER_IP

# Deploy
docker compose -f docker-compose.yml -f docker compose.prod.yml up -d
```

### 3. Docker Swarm
```bash
# Initialize swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker compose.yml -c docker compose.prod.yml plosolver
```

## 🔧 Advanced Configuration

### Custom Traefik Rules
Add custom labels to services in `docker compose.yml`:

```yaml
labels:
  # Custom routing
  - "traefik.http.routers.frontend.rule=Host(`app.example.com`) && PathPrefix(`/poker`)"
  
  # Rate limiting
  - "traefik.http.middlewares.ratelimit.ratelimit.burst=100"
  - "traefik.http.routers.frontend.middlewares=ratelimit"
  
  # IP whitelist
  - "traefik.http.middlewares.ipwhitelist.ipwhitelist.sourcerange=192.168.1.0/24"
```

### Multiple Environments
```bash
# Staging
FRONTEND_DOMAIN=staging.plosolver.com docker compose up -d

# Production
FRONTEND_DOMAIN=plosolver.com docker compose -f docker-compose.yml -f docker compose.prod.yml up -d
```

## 🛠 Troubleshooting

### Common Issues

1. **"Invalid Host header"**
   - Fixed in webpack config with `allowedHosts: 'all'`

2. **SSL Certificate Issues**
   ```bash
   # Check certificate status
   docker compose logs traefik | grep -i acme
   
   # Force certificate renewal
   docker compose restart traefik
   ```

3. **API Not Accessible**
   ```bash
   # Check backend health
   curl http://localhost/api/health
   
   # Verify routing
   docker compose logs traefik | grep backend
   ```

4. **Database Connection Issues**
   ```bash
   # Check database health
   docker compose exec db pg_isready -U postgres
   
   # View backend logs
   docker compose logs backend
   ```

### Performance Tuning

1. **Enable Gzip Compression** (already configured in nginx)
2. **Optimize Database:**
   ```bash
   # Add to docker compose.yml db service
   command: postgres -c shared_preload_libraries=pg_stat_statements
   ```

3. **Scale Services:**
   ```bash
   # Scale backend
   docker compose up -d --scale backend=3
   ```

## 📝 Maintenance

### Backup Database
```bash
# Create backup
docker compose exec db pg_dump -U postgres plosolver > backup.sql

# Restore backup
docker compose exec -T db psql -U postgres plosolver < backup.sql
```

### Update Services
```bash
# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d
```

### Clean Up
```bash
# Remove unused containers/images
docker system prune -a

# Reset everything
docker compose down -v
docker system prune -a
```

## 🔐 Security Checklist

- [ ] Change default passwords in production
- [ ] Use strong `SECRET_KEY`
- [ ] Configure proper `ACME_EMAIL`
- [ ] Disable Traefik dashboard in production
- [ ] Use non-root users in containers
- [ ] Enable security headers
- [ ] Regular security updates
- [ ] Monitor access logs

## 📞 Support

If you encounter issues:
1. Check the logs: `docker compose logs -f`
2. Verify configuration: `docker compose config`
3. Test connectivity: `curl -v http://localhost/health`
4. Review Traefik dashboard: http://localhost:8080

---

**Happy PLO Solving! 🃏** 