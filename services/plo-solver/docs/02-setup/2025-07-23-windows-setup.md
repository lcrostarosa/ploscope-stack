## Windows Setup (WSL2 Recommended)

This installs dependencies on Windows using WSL2 and Docker Desktop, then runs the app with `make`.

### Prerequisites

- Windows 10 2004+ or Windows 11
- Administrator PowerShell (first-time WSL install)

### Quick Start

1. Clone the repo
   ```powershell
   git clone https://github.com/your-repo/PLOSolver.git
   cd PLOSolver
   ```

2. Run the setup script (PowerShell from repo root)
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\setup\setup-dependencies.ps1
   ```
   This will:
   - Install WSL2 and Ubuntu 22.04 (if missing)
   - Install Docker Desktop (if missing)
   - Install Python 3.11, Node.js LTS, build tools inside WSL
   - Run `make deps-python` and `make deps-node` inside WSL

3. Enable WSL integration in Docker Desktop
   - Docker Desktop → Settings → Resources → WSL Integration → enable for `Ubuntu-22.04`

4. Start the app
   ```powershell
   wsl -d Ubuntu-22.04 -- bash -lc "cd $(wslpath -a $(pwd)) && make run-local"
   ```

### Common (inside WSL)

```bash
make run-local
make test-unit
make lint
```

### Notes

- Frontend on port 3001, backend on port 5001
- Prefer `make` targets over raw npm/python commands
- To recreate services: `make run-local ARGS="--recreate"`

### Troubleshooting

- If prompted, reboot after WSL/Docker install, then re-run the setup script.
- Install Docker Desktop manually if needed: `https://www.docker.com/products/docker-desktop`
- If Node/Python are missing inside WSL: `sudo apt-get update && sudo apt-get install -y python3.11 python3.11-venv python3-pip` then `make deps-python && make deps-node`.


