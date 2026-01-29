# PLOSolver Beta Deployment Guide - DigitalOcean

This guide will help you deploy PLOSolver to DigitalOcean for beta testing at the lowest cost.

## Prerequisites

- Domain name (can get one for ~$12/year from Namecheap, Google Domains, etc.)
- DigitalOcean account
- GitHub repository with your code

## Step 1: Create DigitalOcean Droplet

1. **Create Droplet**:
   - **Image**: Docker on Ubuntu 22.04
   - **Size**: Basic Regular - $12/month (1 vCPU, 2GB RAM) or $20/month (2 vCPUs, 4GB RAM)
   - **Region**: Choose closest to your users
   - **Authentication**: SSH keys (recommended) or root password

2. **Connect to your droplet**:
   ```bash
   ssh root@your-droplet-ip
   ```

## Step 2: Domain Setup

1. **Point your domain to the droplet**:
   - Add A record: `@` → `your-droplet-ip`
   - Add A record: `www` → `your-droplet-ip`
   - (Optional) Add A record: `forum` → `your-droplet-ip`

## Step 3: Server Setup

```bash
# Update the system
apt update && apt upgrade -y

# Install additional tools
apt install -y git curl

# Clone your repository
git clone https://github.com/your-username/plo-solver.git
cd plo-solver

# Create production environment file
cp env.production .env
```

## Step 4: Configure Environment Variables

Edit your `.env` file:

```bash
nano .env
```

**Critical settings to change:**

```env
# Domain Configuration
FRONTEND_DOMAIN=yourdomain.com
TRAEFIK_DOMAIN=yourdomain.com
ACME_EMAIL=your-email@yourdomain.com

# Security (CHANGE THESE!)
SECRET_KEY=your-super-secure-production-secret-key-here
JWT_SECRET_KEY=your-production-jwt-secret-key-here
POSTGRES_PASSWORD=your-secure-production-password-here

# Disable forum initially to save resources
DISCOURSE_ENABLED=false

# OAuth (configure later)
REACT_APP_GOOGLE_CLIENT_ID=your-google-client-id
REACT_APP_FACEBOOK_APP_ID=your-facebook-app-id

# Stripe (configure when ready)
STRIPE_SECRET_KEY=sk_test_your_test_stripe_secret_key
STRIPE_PUBLISHABLE_KEY=pk_test_your_test_stripe_publishable_key
```

## Step 5: Deploy the Application

```bash
# Make script executable
chmod +x run_with_traefik.sh

# Start the application (without forum for now)
./run_with_traefik.sh --production

# Check if everything is running
docker ps
```

## Step 6: Verify Deployment

1. **Check services**:
   ```bash
   # View running containers
   docker ps
   
   # Check logs if needed
   docker logs plosolver-backend-1
   docker logs plosolver-frontend-1
   ```

2. **Access your application**:
   - Frontend: `https://yourdomain.com`
   - API: `https://yourdomain.com/api`
   - Traefik Dashboard (if enabled): `https://yourdomain.com:8080`

## Step 7: Set Up Monitoring

```bash
# Create simple monitoring script
cat > /root/check-app.sh << 'EOF'
#!/bin/bash
curl -f https://yourdomain.com > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "App is down, restarting..."
    cd /root/plo-solver && ./run_with_traefik.sh --production
fi
EOF

chmod +x /root/check-app.sh

# Add to crontab (check every 5 minutes)
(crontab -l ; echo "*/5 * * * * /root/check-app.sh") | crontab -
```

## Cost Optimization Tips

### Start Small ($12/month total)
- **Droplet**: $12/month (1 vCPU, 2GB RAM)
- **Domain**: ~$12/year ($1/month)
- **Total**: ~$13/month

### Disable Expensive Features Initially
```env
# In your .env file
DISCOURSE_ENABLED=false
TRAEFIK_DASHBOARD_ENABLED=false
```

### Monitor Resource Usage
```bash
# Check memory usage
free -h

# Check disk usage
df -h

# Check running processes
htop
```

## Scaling Up Later

When your beta grows, easily upgrade:

1. **Resize droplet** through DigitalOcean panel
2. **Enable forum**:
   ```env
   DISCOURSE_ENABLED=true
   ```
3. **Add load balancing** if needed

## Backup Strategy

```bash
# Create backup script
cat > /root/backup.sh << 'EOF'
#!/bin/bash
cd /root/plo-solver
docker exec plosolver-db-1 pg_dump -U postgres plosolver > backups/backup-$(date +%Y%m%d).sql
# Keep only last 7 days
find backups/ -name "backup-*.sql" -mtime +7 -delete
EOF

chmod +x /root/backup.sh

# Daily backup at 2 AM
(crontab -l ; echo "0 2 * * * /root/backup.sh") | crontab -
```

## SSL Certificate

Your setup automatically gets SSL certificates from Let's Encrypt via Traefik. No additional configuration needed!

## Troubleshooting

### App won't start
```bash
# Check logs
docker logs plosolver-backend-1
docker logs plosolver-frontend-1

# Restart services
docker compose down && ./run_with_traefik.sh --production
```

### SSL issues
```bash
# Check Traefik logs
docker logs plosolver-traefik-1

# Verify domain points to server
nslookup yourdomain.com
```

### Out of memory
```bash
# Check memory usage
free -h

# If needed, add swap
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile swap swap defaults 0 0' >> /etc/fstab
```

## Next Steps

1. **Configure OAuth** (Google/Facebook login)
2. **Set up Stripe** for subscriptions
3. **Enable forum** when ready for community features
4. **Set up proper monitoring** (consider Uptime Robot - free tier)
5. **Configure backups** to DigitalOcean Spaces or AWS S3

## Total Beta Deployment Cost

- **Minimum**: $12/month (small droplet + domain)
- **Recommended**: $20/month (medium droplet + domain)
- **With all features**: $25-30/month (larger droplet + forum)

This gives you a professional, scalable platform for your beta testers at an extremely low cost! 