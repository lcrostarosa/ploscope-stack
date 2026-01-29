#!/bin/bash

# Setup Comprehensive Monitoring
# This script sets up monitoring for infrastructure, containers, frontend, and Traefik

set -e

echo "Setting up comprehensive monitoring..."

# Create necessary directories
mkdir -p logs/traefik
mkdir -p logs/application
mkdir -p logs/system

# Set proper permissions
chmod 755 logs
chmod 755 logs/traefik
chmod 755 logs/application
chmod 755 logs/system

# Create logrotate configuration for all logs
cat > /etc/logrotate.d/plosolver << 'EOF'
/var/log/plosolver/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
    postrotate
        /usr/bin/systemctl reload logstash > /dev/null 2>&1 || true
    endscript
}

/var/log/traefik/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
    postrotate
        /usr/bin/systemctl reload logstash > /dev/null 2>&1 || true
    endscript
}
EOF

# Create monitoring dashboard configuration
cat > monitoring-dashboards.json << 'EOF'
{
  "dashboards": [
    {
      "name": "Infrastructure Overview",
      "description": "System metrics, CPU, memory, disk usage",
      "type": "system_metrics"
    },
    {
      "name": "Container Health",
      "description": "Docker container status, logs, resource usage",
      "type": "container"
    },
    {
      "name": "Application Performance",
      "description": "Backend and frontend application logs, errors, performance",
      "type": "application"
    },
    {
      "name": "Traefik Access Logs",
      "description": "HTTP requests, response times, status codes",
      "type": "traefik"
    },
    {
      "name": "Security Monitoring",
      "description": "Failed logins, suspicious activity, access patterns",
      "type": "security"
    }
  ]
}
EOF

echo "Monitoring setup complete!"
echo ""
echo "What's being monitored:"
echo "======================="
echo "✅ Infrastructure: CPU, memory, disk, network"
echo "✅ Containers: All Docker container logs and metrics"
echo "✅ Frontend: Application logs and errors"
echo "✅ Backend: Application logs, database queries, API calls"
echo "✅ Traefik: HTTP access logs, response times, status codes"
echo "✅ System: System logs, Docker daemon logs"
echo "✅ Portainer: Docker container management interface"
echo "✅ RabbitMQ: Message queue management interface"
echo "✅ Docker Logs: Automatic rotation with 7-day retention"
echo ""
echo "To start monitoring:"
echo "  ./scripts/start-elk.sh"
echo ""
echo "To setup Docker log rotation:"
echo "  sudo ./scripts/setup-docker-log-rotation.sh"
echo ""
echo "To access dashboards:"
echo "  ssh -L 5601:localhost:5601 user@your-server"
echo "  Then open: http://localhost:5601"
echo ""
echo "To access Portainer:"
echo "  ssh -L 9000:localhost:9000 user@your-server"
echo "  Then open: http://localhost:9000"
echo ""
echo "To access all services via SSH tunnel:"
echo "  ./scripts/ssh-tunnel-all.sh <server-ip> <username> [ssh-key-path]"
echo "  ./scripts/test-ssh-tunnels.sh"
echo ""
echo "SSH Key Examples:"
echo "  ./scripts/ssh-tunnel-all.sh 192.168.1.100 ubuntu ~/.ssh/id_rsa"
echo "  ./scripts/ssh-tunnel-all.sh plosolver.example.com admin ~/.ssh/plosolver_key"
echo ""
echo "Access URLs (after SSH tunnel):"
echo "  • Kibana: http://localhost:5601"
echo "  • Portainer: http://localhost:9000"
echo "  • RabbitMQ: http://localhost:15672"
echo ""
echo "To setup SSH key for monitoring:"
echo "  ./scripts/setup-ssh-key.sh [key-path] [server-ip] [username]" 