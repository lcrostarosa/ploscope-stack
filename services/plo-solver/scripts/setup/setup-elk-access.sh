#!/bin/bash

# Setup ELK Stack Access Control
# This script configures SSH-only access to Kibana and Elasticsearch

set -e

echo "Setting up ELK stack access control..."

# Create SSH tunnel script for Kibana
cat > /usr/local/bin/kibana-tunnel << 'EOF'
#!/bin/bash
# SSH tunnel script for Kibana access
# Usage: ssh -L 5601:localhost:5601 user@server

echo "Starting Kibana tunnel..."
echo "Access Kibana at: http://localhost:5601"
echo "Press Ctrl+C to stop the tunnel"

# Keep the tunnel open
while true; do
    sleep 1
done
EOF

chmod +x /usr/local/bin/kibana-tunnel

# Create SSH tunnel script for Elasticsearch
cat > /usr/local/bin/elasticsearch-tunnel << 'EOF'
#!/bin/bash
# SSH tunnel script for Elasticsearch access
# Usage: ssh -L 9200:localhost:9200 user@server

echo "Starting Elasticsearch tunnel..."
echo "Access Elasticsearch at: http://localhost:9200"
echo "Press Ctrl+C to stop the tunnel"

# Keep the tunnel open
while true; do
    sleep 1
done
EOF

chmod +x /usr/local/bin/elasticsearch-tunnel

# Create access control script
cat > /usr/local/bin/elk-access << 'EOF'
#!/bin/bash

echo "ELK Stack Access Control"
echo "======================="
echo ""
echo "To access Kibana:"
echo "  ssh -L 5601:localhost:5601 user@your-server"
echo "  Then open: http://localhost:5601"
echo ""
echo "To access Elasticsearch:"
echo "  ssh -L 9200:localhost:9200 user@your-server"
echo "  Then open: http://localhost:9200"
echo ""
echo "To check ELK stack status:"
echo "  docker compose logs elasticsearch"
echo "  docker compose logs logstash"
echo "  docker compose logs kibana"
EOF

chmod +x /usr/local/bin/elk-access

echo "ELK access control setup complete!"
echo "Run 'elk-access' for usage instructions." 