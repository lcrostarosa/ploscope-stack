# PLOScope Frontend

This is the frontend application for PLOScope, a poker equity calculator and solver.

To start

```bash
npm install
```

## Development Setup

This project supports two development modes:

1. **Fully Local Development** - All services run locally
2. **Staging Development** - Frontend runs locally, connects to staging backend

### Fully local development with docker

#### Pre Requisites

- Docker
- Access to PLOScope Docker Hub
- npm

#### Procedure

- `docker login`
- `make local-docker-bootstrap`
- `make local-infra`
- for logs: `docker compose logs -f`
- Start frontend `npm run dev`

### Staging Connection

#### Procedure

- `npm run dev:staging`

## Troubleshooting Local Development Issues

**Backend Services Not Starting**:

```bash
# Check Docker services
docker-compose ps

# Check logs
docker-compose logs db
docker-compose logs backend
```

**Port Conflicts**:

```bash
# Check what's using the ports
lsof -i :3001
lsof -i :5001
lsof -i :5432
```

#### Staging Development Issues

**SSH Connection Issues**:

```bash
# Check SSH key permissions
chmod 600 ~/.ssh/plo-scope-staging
chmod 644 ~/.ssh/plo-scope-staging.pub

# Test SSH connection
ssh -i ~/.ssh/plo-scope-staging -o ConnectTimeout=10 appuser@5.78.113.169
```

**Database Connection Issues**:

```bash
# Check if tunnel is active
netstat -an | grep 5433

# Test database connection
psql -h localhost -p 5433 -U postgres -d plosolver -c "SELECT 1;"
```

**CORS Issues**:

- Ensure Traefik staging configuration is updated
- Check that `https://staging.ploscope.com` is in CORS origins
- Verify frontend is running on `localhost:3001`

**API Call Failures**:

```bash
# Test API endpoint
curl -H "Origin: http://localhost:3001" \
     -H "Access-Control-Request-Method: GET" \
     -H "Access-Control-Request-Headers: X-Requested-With" \
     -X OPTIONS \
     https://staging.ploscope.com/api/health
```

## Choosing Your Development Setup

**Use Fully Local Development when:**

- You want to work offline
- You need to modify backend code
- You want to test with local data
- You're setting up the project for the first time

**Use Staging Development when:**

- You want to test against real staging data
- You're only working on frontend changes
- You want to verify integration with staging backend
- You need to test with production-like data
