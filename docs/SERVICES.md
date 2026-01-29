# PLOScope Services Reference

## Quick Reference

| Service | Port(s) | Image | Repository |
|---------|---------|-------|------------|
| traefik | 80, 443, 8080 | traefik:v3.4.4 | [PLOScope/traefik](https://github.com/PLOScope/traefik) |
| frontend | 3000 | ghcr.io/ploscope/frontend | [PLOScope/frontend](https://github.com/PLOScope/frontend) |
| backend | 5001 | ghcr.io/ploscope/backend | [PLOScope/backend](https://github.com/PLOScope/backend) |
| backend-grpc | 50051 | ghcr.io/ploscope/backend | [PLOScope/backend](https://github.com/PLOScope/backend) |
| celery-worker | - | ghcr.io/ploscope/celery-worker | [PLOScope/celery-worker](https://github.com/PLOScope/celery-worker) |
| db | 5432 | postgres:15-alpine | - |
| redis | 6379 | redis:7-alpine | [PLOScope/redis](https://github.com/PLOScope/redis) |
| rabbitmq | 5672, 15672 | rabbitmq:3.13-management | [PLOScope/rabbitmq](https://github.com/PLOScope/rabbitmq) |
| rabbitmq-init | - | ghcr.io/ploscope/rabbitmq-init | [PLOScope/rabbitmq](https://github.com/PLOScope/rabbitmq) |
| db-init | - | ghcr.io/ploscope/db-init | [PLOScope/db-init](https://github.com/PLOScope/db-init) |
| prometheus | 9090 | prom/prometheus | [PLOScope/monitoring](https://github.com/PLOScope/monitoring) |
| grafana | 3001 | grafana/grafana | [PLOScope/monitoring](https://github.com/PLOScope/monitoring) |
| loki | 3100 | grafana/loki | [PLOScope/monitoring](https://github.com/PLOScope/monitoring) |

---

## Infrastructure Services

### Traefik

**Purpose**: Reverse proxy, load balancer, SSL termination

**Ports**:
- 80: HTTP (redirects to HTTPS in production)
- 443: HTTPS
- 8080: Dashboard/API

**Health Check**: `GET http://localhost:8080/api/rawdata`

**Configuration**:
- Labels on containers define routing rules
- Automatic Let's Encrypt certificate provisioning
- Docker provider for service discovery

**Key Environment Variables**:
```bash
TRAEFIK_DOMAIN=ploscope.com
TRAEFIK_LOG_LEVEL=INFO
ACME_EMAIL=admin@ploscope.com
```

---

### PostgreSQL (db)

**Purpose**: Primary relational database

**Port**: 5432

**Health Check**: `pg_isready -U postgres -d plosolver`

**Default Database**: `plosolver`

**Key Environment Variables**:
```bash
POSTGRES_USER=postgres
POSTGRES_PASSWORD=<secret>
POSTGRES_DB=plosolver
```

**Volumes**:
- `postgres-data`: Database files
- `postgres-backups`: Backup storage

**Backup Command**:
```bash
docker compose exec db pg_dump -U postgres plosolver > backup.sql
```

---

### Redis

**Purpose**: Caching, session storage, Celery result backend

**Port**: 6379

**Health Check**: `redis-cli ping`

**Key Environment Variables**:
```bash
REDIS_PASSWORD=<secret>
```

**Usage**:
- API response caching
- User session storage
- Celery task results
- Rate limiting counters

---

### RabbitMQ

**Purpose**: Message broker for async task processing

**Ports**:
- 5672: AMQP protocol
- 15672: Management UI

**Health Check**: `rabbitmq-diagnostics ping`

**Key Environment Variables**:
```bash
RABBITMQ_USERNAME=plosolver
RABBITMQ_PASSWORD=<secret>
RABBITMQ_VHOST=/plosolver
```

**Queues**:
| Queue | Purpose |
|-------|---------|
| spot-processing | Spot analysis tasks |
| solver-processing | Solver computation tasks |
| spot-processing-dlq | Failed spot tasks |
| solver-processing-dlq | Failed solver tasks |

**Management UI**: http://localhost:15672

---

## Application Services

### Frontend

**Purpose**: React single-page application

**Port**: 3000

**Health Check**: `GET http://localhost:3000`

**Technology**: React, TypeScript, Vite

**Key Environment Variables**:
```bash
REACT_APP_API_URL=/api
REACT_APP_FEATURE_SOLVER_MODE_ENABLED=true
```

**Features**:
- Poker hand visualization
- Analysis interface
- User authentication (Google OAuth)
- WebSocket for real-time updates

---

### Backend

**Purpose**: REST API server

**Port**: 5001

**Health Check**: `GET http://localhost:5001/api/health`

**Technology**: Flask, Gunicorn, Eventlet

**Key Environment Variables**:
```bash
FLASK_ENV=production
DATABASE_URL=postgresql://...
RABBITMQ_HOST=rabbitmq
REDIS_HOST=redis
SECRET_KEY=<secret>
JWT_SECRET_KEY=<secret>
```

**API Endpoints**:
| Endpoint | Method | Description |
|----------|--------|-------------|
| /api/health | GET | Health check |
| /api/auth/* | POST | Authentication |
| /api/users/* | GET/POST | User management |
| /api/hands/* | GET/POST | Hand analysis |
| /api/solver/* | POST | Solver requests |

**Features**:
- JWT authentication
- WebSocket (Socket.IO) support
- Request rate limiting
- OpenAPI documentation

---

### Backend gRPC

**Purpose**: High-performance RPC server for solver communication

**Port**: 50051

**Health Check**: `nc -z localhost 50051`

**Technology**: Python gRPC

**Key Environment Variables**:
```bash
GRPC_PORT=50051
DATABASE_URL=postgresql://...
```

**Services**:
- Solver computation interface
- Binary data transfer
- Streaming results

---

### Celery Worker

**Purpose**: Asynchronous task processing

**Ports**: None (internal only)

**Health Check**: Custom health check script

**Technology**: Celery, RabbitMQ broker

**Key Environment Variables**:
```bash
CELERY_BROKER_URL=amqp://...
CELERY_RESULT_BACKEND=redis://...
CELERY_WORKER_CONCURRENCY=4
```

**Task Types**:
| Task | Queue | Description |
|------|-------|-------------|
| analyze_spot | spot-processing | Analyze single spot |
| run_solver | solver-processing | Execute solver |
| process_hand | spot-processing | Parse hand history |

---

## Init Services

### db-init

**Purpose**: Run database migrations

**Runs**: Once at startup

**Technology**: Alembic (Python)

**Behavior**:
- Waits for PostgreSQL to be healthy
- Runs pending migrations
- Exits with code 0 on success

---

### rabbitmq-init

**Purpose**: Create RabbitMQ queues, exchanges, bindings

**Runs**: Once at startup

**Technology**: Python (pika)

**Creates**:
- Vhost: `/plosolver`
- Exchanges: `plosolver.main`, `plosolver.dlq`
- Queues: spot-processing, solver-processing, DLQs
- Bindings between exchanges and queues

---

## Monitoring Services

### Prometheus

**Purpose**: Metrics collection and storage

**Port**: 9090

**Health Check**: `GET http://localhost:9090/-/healthy`

**Profile**: `monitoring`

**Scrape Targets**:
- Traefik metrics
- Backend metrics
- Celery metrics
- Self-monitoring

---

### Grafana

**Purpose**: Metrics visualization and dashboards

**Port**: 3001

**Health Check**: `GET http://localhost:3000/api/health`

**Profile**: `monitoring`

**Default Credentials**: admin / admin

**Pre-configured Datasources**:
- Prometheus
- Loki

---

### Loki

**Purpose**: Log aggregation

**Port**: 3100

**Health Check**: `GET http://localhost:3100/ready`

**Profile**: `monitoring`

**Log Sources**:
- Container stdout/stderr
- Application log files

---

## Service Dependencies

```
db-init ─────────► db ◄───────┬────────┬────────┐
                              │        │        │
rabbitmq-init ─► rabbitmq ◄──┼────────┼────────┤
                              │        │        │
redis ◄──────────────────────┼────────┼────────┤
                              │        │        │
                              ▼        ▼        ▼
                           backend  backend  celery-
                                    -grpc    worker
                              │
                              ▼
                           frontend
                              │
                              ▼
                           traefik
```

## Resource Requirements

| Service | CPU | Memory | Storage |
|---------|-----|--------|---------|
| traefik | 0.1-0.5 | 64-256 MB | Minimal |
| db | 0.5-2 | 512 MB-2 GB | 10+ GB |
| redis | 0.1-0.5 | 128-512 MB | 1 GB |
| rabbitmq | 0.25-1 | 256 MB-1 GB | 1 GB |
| backend | 0.5-2 | 512 MB-2 GB | Minimal |
| frontend | 0.1-0.5 | 64-256 MB | Minimal |
| celery-worker | 0.5-2 | 512 MB-2 GB | Minimal |
| prometheus | 0.25-1 | 512 MB-2 GB | 10+ GB |
| grafana | 0.1-0.5 | 128-512 MB | 1 GB |
