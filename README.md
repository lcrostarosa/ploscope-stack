# PLOScope Stack

Central orchestration repository for the PLOScope poker analysis platform.

## ⚠️ Project Status

This project was originally launched in early June 2025, but I have since shifted my priorities to other endeavors. This orchestration repo exists to make it easier to spin up and understand the full stack if anyone wants to revisit it.

The codebase may be outdated and some services may need updates to work with current dependencies.

---

## What is PLOScope?

**PLOScope** (formerly PLOSolver) is a **Pot Limit Omaha (PLO) Double Board Bomb Pot equity calculator and solver**.

### Poker Concepts Explained

- **PLO (Pot Limit Omaha)**: A poker variant where players get 4 hole cards (instead of 2 in Texas Hold'em) and must use exactly 2 of them with 3 community cards
- **Bomb Pot**: A poker variant where all players ante a set amount and skip preflop betting, going directly to the flop
- **Double Board**: Two separate community boards run simultaneously, with the pot split 50/50 between the winner of each board (or "scooped" if one player wins both)
- **Equity Calculator**: Calculates the probability of winning given specific cards and board states
- **GTO Solver**: Uses Counterfactual Regret Minimization (CFR) to find game-theory optimal strategies

### Core Features

- **Real-time equity calculations** for PLO hands across two boards
- **GTO solver** for finding optimal bet/check/fold strategies
- **Hand history import** - upload hand histories from poker sites
- **Job queue system** for computationally expensive solver runs
- **Credit-based usage** with Stripe payment integration
- **User authentication** via Google OAuth or email/password
- **WebSocket updates** for real-time solver progress

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Internet                                        │
└───────────────────────────────────┬─────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Traefik (Reverse Proxy)                              │
│                    SSL Termination, Routing, Load Balancing                  │
│                           :80 / :443 / :8080                                 │
└───────────────────────────────────┬─────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           ▼
┌───────────────┐         ┌─────────────────┐         ┌─────────────────┐
│   Frontend    │         │     Backend     │         │  Backend gRPC   │
│   (React)     │────────▶│   (Flask API)   │◀───────▶│   (gRPC)        │
│    :3000      │         │     :5001       │         │    :50051       │
└───────────────┘         └────────┬────────┘         └────────┬────────┘
                                   │                           │
        ┌──────────────────────────┼───────────────────────────┤
        │                          │                           │
        ▼                          ▼                           ▼
┌───────────────┐         ┌─────────────────┐         ┌─────────────────┐
│  PostgreSQL   │         │    RabbitMQ     │         │      Redis      │
│   (Database)  │         │ (Message Queue) │         │     (Cache)     │
│    :5432      │         │  :5672/:15672   │         │     :6379       │
└───────────────┘         └────────┬────────┘         └─────────────────┘
                                   │
                                   ▼
                          ┌─────────────────┐
                          │  Celery Worker  │
                          │ (Solver Tasks)  │
                          └─────────────────┘
```

---

## 📦 Repository Structure

All services are contained in the `services/` directory of this monorepo.

### Core Application (What Makes PLOScope Work)

| Service | Technology | Purpose | Status |
|---------|------------|---------|--------|
| [**backend**](./services/backend) | Python 3.11, Flask, SQLAlchemy, gRPC | REST API, WebSocket server, authentication, job submission | ✅ Has Dockerfile |
| [**frontend**](./services/frontend) | React 18, TypeScript, Webpack | Web UI for equity calculator, hand input, results display | ✅ Has Dockerfile |
| [**core**](./services/core) | Python, NumPy, Treys | Equity calculation engine, CFR solver, card utilities | 📦 Python package (no Dockerfile) |
| [**celery-worker**](./services/celery-worker) | Python, Celery | Background job processing for solver computations | ✅ Has Dockerfile |

### Database & Migrations

| Service | Technology | Purpose | Status |
|---------|------------|---------|--------|
| [**database**](./services/database) | PostgreSQL 15, Alembic | Database schema, migration definitions | ✅ Has Dockerfile |
| [**db-init**](./services/db-init) | Python, Alembic | Migration runner (init container) | ✅ Has Dockerfile |

### Message Queue

| Service | Technology | Purpose | Status |
|---------|------------|---------|--------|
| [**rabbitmq**](./services/rabbitmq) | RabbitMQ 3.13 | Message broker for async job processing | ✅ Has Dockerfile |
| [**rabbitmq-init**](./services/rabbitmq-init) | Python, Pika | Creates vhosts, exchanges, queues on startup | ✅ Has Dockerfile |

### Infrastructure

| Service | Technology | Purpose | Status |
|---------|------------|---------|--------|
| [**traefik**](./services/traefik) | Traefik v3 | Reverse proxy, SSL, routing | 📄 Config only |
| [**redis**](./services/redis) | Redis 7 | Caching, Celery result backend | 📄 Compose only |
| [**monitoring**](./services/monitoring) | Prometheus, Grafana, Loki, Tempo | Observability stack | 📄 Compose + configs |
| [**vault**](./services/vault) | HashiCorp Vault | Secrets management (optional) | 📄 Compose only |
| [**nexus**](./services/nexus) | Sonatype Nexus | Private PyPI/npm registry | 📄 Compose + scripts |

### CI/CD & Deployment

| Service | Technology | Purpose | Status |
|---------|------------|---------|--------|
| [**ansible**](./services/ansible) | Ansible | Server provisioning playbooks | 📄 Playbooks only |
| [**jenkins**](./services/jenkins) | Jenkins | CI/CD pipeline definitions | ✅ Has Dockerfile |

### Additional Services

| Service | Purpose | Status |
|---------|---------|--------|
| [**plo-solver**](./services/plo-solver) | Original monorepo (now split) | ⚠️ Deprecated - use individual services |
| [**simulation-tool**](./services/simulation-tool) | Standalone simulation utilities | 📄 Scripts |
| [**admin-scripts**](./services/admin-scripts) | Administrative scripts | 📄 Scripts |
| [**actions**](./services/actions) | GitHub Actions workflows | 📄 Workflows |
| [**postman**](./services/postman) | API collection & tests | 📄 Collections |
| [**openvpn**](./services/openvpn) | VPN configuration | 📄 Config |
| [**coreDNS**](./services/coreDNS) | DNS configuration | 📄 Config |

---

## 🔧 Technology Stack

### Backend
- **Python 3.11** with Poetry for dependency management
- **Flask 3.x** - REST API framework
- **SQLAlchemy 2.x** - ORM
- **Flask-SocketIO** - WebSocket support
- **gRPC** - High-performance RPC (for solver communication)
- **Celery 5.x** - Distributed task queue
- **Alembic** - Database migrations

### Frontend
- **React 18** with TypeScript
- **Webpack 5** - Bundling
- **React Bootstrap** - UI components
- **Socket.IO Client** - Real-time updates

### Infrastructure
- **PostgreSQL 15** - Primary database
- **Redis 7** - Caching & Celery results
- **RabbitMQ 3.13** - Message broker
- **Traefik v3** - Reverse proxy with auto SSL
- **Docker & Docker Compose** - Containerization

### Monitoring (Optional)
- **Prometheus** - Metrics collection
- **Grafana** - Dashboards
- **Loki** - Log aggregation
- **Grafana Alloy** - Telemetry collector

---

## 🚀 Quick Start

### Prerequisites

- Docker Engine 24.0+
- Docker Compose v2.20+
- 8GB+ RAM recommended

### Option 1: Production Mode (Pre-built Images)

```bash
# Clone this repository
git clone https://github.com/lcrostarosa/ploscope-stack.git
cd ploscope-stack

# Copy environment template
cp .env.example .env

# Run setup wizard (generates secrets, creates network)
./scripts/setup.sh

# Start the stack
docker compose up -d

# Check status
docker compose ps
```

### Option 2: Development Mode (Build from Source)

```bash
# Clone this repository
git clone https://github.com/lcrostarosa/ploscope-stack.git
cd ploscope-stack

# Copy environment template
cp .env.example .env

# Start with hot reload
./scripts/dev.sh up
```

### Service URLs

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| Frontend | http://localhost:3000 | - |
| Backend API | http://localhost:5001/api | - |
| Traefik Dashboard | http://localhost:8080 | - |
| RabbitMQ Management | http://localhost:15672 | plosolver / (from .env) |
| Grafana | http://localhost:3001 | admin / admin |
| Prometheus | http://localhost:9090 | - |

---

## ⚠️ Known Issues & Considerations

### Potential Outdated Dependencies

1. **Python packages** - The backend uses `poetry.lock` which pins exact versions. May need `poetry update` for security patches.

2. **Node.js packages** - Frontend `package-lock.json` may have outdated dependencies. Run `npm audit` to check.

3. **Docker base images** - Dockerfiles use specific versions (e.g., `python:3.11.9-slim`). Consider updating for security.

### Missing/Incomplete Pieces

1. **Nexus Registry** - The build process expects a private PyPI registry at `nexus.ploscope.com`. For local development, you'll need to either:
   - Set up your own Nexus instance
   - Modify Dockerfiles to use public PyPI
   - Use the `core` package from source

2. **Google OAuth** - Requires setting up a Google Cloud project and OAuth credentials for authentication to work.

3. **Stripe Integration** - Payment features require Stripe API keys and webhook configuration.

### Environment-Specific Notes

- **CORS Origins** - The default CORS configuration includes `ploscope.com`. Update for your domain.
- **SSL Certificates** - Production mode expects Let's Encrypt. Needs valid domain and open ports 80/443.
- **Database** - No seed data included. First user may need manual admin flag.

---

## 📁 Project Structure

```
ploscope-stack/
├── docker-compose.yml          # Main orchestration (uses pre-built images)
├── docker-compose.dev.yml      # Development overrides (builds from source)
├── docker-compose.prod.yml     # Production overrides (HTTPS, replicas)
├── .env.example                # Environment template (copy to .env)
├── Makefile                    # Common operations
│
├── scripts/
│   ├── setup.sh               # Interactive setup wizard
│   ├── dev.sh                 # Development environment manager
│   └── build-all.sh           # Build all Docker images locally
│
├── config/
│   ├── prometheus/            # Prometheus scrape configs
│   ├── grafana/               # Grafana provisioning
│   └── loki/                  # Loki log aggregation
│
├── docs/
│   ├── ARCHITECTURE.md        # System architecture details
│   ├── DEVELOPMENT.md         # Local development guide
│   ├── DEPLOYMENT.md          # Production deployment
│   └── SERVICES.md            # Service reference
│
└── services/                  # All PLOScope services
    ├── backend/               # Flask REST API server
    ├── frontend/              # React web application
    ├── core/                  # Core Python equity calculation library
    ├── celery-worker/         # Background job processing
    ├── database/              # PostgreSQL schema & migrations
    ├── db-init/               # Database initialization container
    ├── redis/                 # Redis cache configuration
    ├── rabbitmq/              # RabbitMQ message broker config
    ├── rabbitmq-init/         # RabbitMQ initialization container
    ├── traefik/               # Reverse proxy configuration
    ├── monitoring/            # Prometheus, Grafana, Loki stack
    ├── nexus/                 # Private PyPI/npm registry
    ├── vault/                 # HashiCorp Vault secrets management
    ├── ansible/               # Server provisioning playbooks
    ├── jenkins/               # CI/CD pipeline definitions
    ├── plo-solver/            # Original monorepo (deprecated)
    ├── simulation-tool/       # Standalone simulation utilities
    ├── admin-scripts/         # Administrative scripts
    ├── actions/               # GitHub Actions workflows
    ├── postman/               # API collection & tests
    ├── openvpn/               # VPN configuration
    └── coreDNS/               # DNS configuration
```

---

## 🛠️ Common Commands

```bash
# Using the dev script
./scripts/dev.sh up              # Start development environment
./scripts/dev.sh logs            # Follow all logs
./scripts/dev.sh logs backend    # Follow specific service
./scripts/dev.sh shell backend   # Shell into container
./scripts/dev.sh down            # Stop everything

# Using make
make help                        # Show all commands
make dev                         # Start dev environment
make status                      # Show service health
make db-shell                    # PostgreSQL shell
make db-backup                   # Backup database
make reset                       # Nuclear option - wipe everything

# Direct docker compose
docker compose ps                # List containers
docker compose logs -f backend   # Follow backend logs
docker compose exec backend bash # Shell into backend
```

---

## 📊 Data Model

### Core Tables

```
users
├── id (UUID)
├── email
├── username
├── password_hash
├── google_id / facebook_id
├── subscription_tier
├── stripe_customer_id
└── created_at / updated_at

jobs
├── id (UUID)
├── user_id (FK)
├── job_type (spot_simulation, solver_analysis)
├── status (pending, running, completed, failed)
├── input_data (JSON)
├── result_data (JSON)
└── created_at / completed_at

spots
├── id (UUID)
├── user_id (FK)
├── name
├── board_top / board_bottom
├── hands (JSON array)
└── created_at

hand_histories
├── id (UUID)
├── user_id (FK)
├── filename
├── raw_content
├── parsed_data (JSON)
└── uploaded_at
```

---

## 🔒 Security Notes

- **Never commit `.env`** - Contains secrets
- **Rotate secrets regularly** - Especially in production
- **Use Docker secrets** - For sensitive build args (Nexus credentials)
- **Enable HTTPS** - Use `docker-compose.prod.yml` in production
- **Database access** - Not exposed externally by default

---

## 📄 License

PolyForm Noncommercial License 1.0.0 - See [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- [Treys](https://github.com/ihendley/treys) - Python poker hand evaluation library
- The PLOScope project was built to solve a real problem in the poker community - understanding equity in the increasingly popular double board bomb pot format.
