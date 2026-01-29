#!/bin/bash

# Generate SSL Certificates for Elasticsearch Production
# This script creates a Certificate Authority and certificates for the ELK stack

set -e

CERT_DIR="./server/elasticsearch/certs"
CA_PASSWORD=${CA_PASSWORD:-"elasticsearch-ca-password-2024"}
ELASTIC_PASSWORD=${ELASTIC_PASSWORD:-changeme}

echo "Generating SSL certificates for Elasticsearch production..."

# Create certificate directory
mkdir -p "${CERT_DIR}"

# Generate Certificate Authority
echo "Generating Certificate Authority..."
openssl req -x509 -newkey rsa:4096 -keyout "${CERT_DIR}/ca.key" -out "${CERT_DIR}/ca.crt" -days 3650 -nodes \
    -subj "/C=US/ST=CA/L=San Francisco/O=PLOSolver/OU=IT/CN=PLOSolver CA"

# Generate Elasticsearch certificate
echo "Generating Elasticsearch certificate..."
openssl req -newkey rsa:4096 -keyout "${CERT_DIR}/elasticsearch.key" -out "${CERT_DIR}/elasticsearch.csr" -nodes \
    -subj "/C=US/ST=CA/L=San Francisco/O=PLOSolver/OU=IT/CN=elasticsearch"

# Create certificate config
cat > "${CERT_DIR}/elasticsearch.conf" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = CA
L = San Francisco
O = PLOSolver
OU = IT
CN = elasticsearch

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = elasticsearch
DNS.3 = *.elasticsearch
DNS.4 = *.ploscope.com
IP.1 = 127.0.0.1
IP.2 = 172.18.1.12
EOF

# Sign the certificate
openssl x509 -req -in "${CERT_DIR}/elasticsearch.csr" -CA "${CERT_DIR}/ca.crt" -CAkey "${CERT_DIR}/ca.key" \
    -CAcreateserial -out "${CERT_DIR}/elasticsearch.crt" -days 3650 -extensions v3_req \
    -extfile "${CERT_DIR}/elasticsearch.conf"

# Generate Kibana certificate
echo "Generating Kibana certificate..."
openssl req -newkey rsa:4096 -keyout "${CERT_DIR}/kibana.key" -out "${CERT_DIR}/kibana.csr" -nodes \
    -subj "/C=US/ST=CA/L=San Francisco/O=PLOSolver/OU=IT/CN=kibana"

# Create Kibana certificate config
cat > "${CERT_DIR}/kibana.conf" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = CA
L = San Francisco
O = PLOSolver
OU = IT
CN = kibana

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = kibana
DNS.3 = kibana.ploscope.com
DNS.4 = kibana-staging.ploscope.com
DNS.5 = *.ploscope.com
IP.1 = 127.0.0.1
IP.2 = 172.18.1.14
EOF

# Sign Kibana certificate
openssl x509 -req -in "${CERT_DIR}/kibana.csr" -CA "${CERT_DIR}/ca.crt" -CAkey "${CERT_DIR}/ca.key" \
    -CAcreateserial -out "${CERT_DIR}/kibana.crt" -days 3650 -extensions v3_req \
    -extfile "${CERT_DIR}/kibana.conf"

# Generate Staging Kibana certificate
echo "Generating Staging Kibana certificate..."
openssl req -newkey rsa:4096 -keyout "${CERT_DIR}/kibana-staging.key" -out "${CERT_DIR}/kibana-staging.csr" -nodes \
    -subj "/C=US/ST=CA/L=San Francisco/O=PLOSolver/OU=IT/CN=kibana-staging"

# Create Staging Kibana certificate config
cat > "${CERT_DIR}/kibana-staging.conf" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = CA
L = San Francisco
O = PLOSolver
OU = IT
CN = kibana-staging

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = kibana-staging
DNS.3 = kibana-staging.ploscope.com
DNS.4 = *.ploscope.com
IP.1 = 127.0.0.1
IP.2 = 172.18.1.14
EOF

# Sign Staging Kibana certificate
openssl x509 -req -in "${CERT_DIR}/kibana-staging.csr" -CA "${CERT_DIR}/ca.crt" -CAkey "${CERT_DIR}/ca.key" \
    -CAcreateserial -out "${CERT_DIR}/kibana-staging.crt" -days 3650 -extensions v3_req \
    -extfile "${CERT_DIR}/kibana-staging.conf"

# Copy CA certificate for other services
cp "${CERT_DIR}/ca.crt" "${CERT_DIR}/elasticsearch-ca.crt"

# Set proper permissions
chmod 600 "${CERT_DIR}"/*.key
chmod 644 "${CERT_DIR}"/*.crt

# Clean up temporary files
rm -f "${CERT_DIR}"/*.csr "${CERT_DIR}"/*.conf "${CERT_DIR}"/*.srl

echo "SSL certificates generated successfully!"
echo ""
echo "Certificate files created:"
echo "  - ${CERT_DIR}/ca.crt (Certificate Authority)"
echo "  - ${CERT_DIR}/ca.key (CA Private Key)"
echo "  - ${CERT_DIR}/elasticsearch.crt (Elasticsearch Certificate)"
echo "  - ${CERT_DIR}/elasticsearch.key (Elasticsearch Private Key)"
echo "  - ${CERT_DIR}/kibana.crt (Kibana Certificate)"
echo "  - ${CERT_DIR}/kibana.key (Kibana Private Key)"
echo "  - ${CERT_DIR}/kibana-staging.crt (Staging Kibana Certificate)"
echo "  - ${CERT_DIR}/kibana-staging.key (Staging Kibana Private Key)"
echo "  - ${CERT_DIR}/elasticsearch-ca.crt (CA Certificate for services)"
echo ""
echo "To use in production:"
echo "  1. Copy certificates to your production server"
echo "  2. Set ELASTIC_PASSWORD environment variable"
echo "  3. Run: docker-compose -f docker-compose.yml -f docker-compose.production.yml up -d"
echo ""
echo "To use in staging:"
echo "  1. Copy certificates to your staging server"
echo "  2. Set ELASTIC_PASSWORD environment variable"
echo "  3. Run: docker-compose -f docker-compose.yml -f docker-compose.staging.yml up -d"
echo ""
echo "To change passwords after deployment:"
echo "  ./scripts/operations/elasticsearch-password-manager.sh change-password <username> <new_password>" 