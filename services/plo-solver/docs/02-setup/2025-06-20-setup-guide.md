# Setup Guide

Complete installation and setup instructions for PLOSolver.

## 🚀 Quick Setup (Recommended)

For most users, this is all you need:

```bash
# Clone the repository
git clone https://github.com/your-repo/PLOSolver.git
cd PLOSolver

# Install all dependencies
make deps

# Run the application
make run
```

## 🔧 Manual Setup

If you prefer to set up components individually:

### 1. Prerequisites

**System Requirements:**
- Python 3.8 or higher
- Node.js 16 or higher
- Git

**Check your versions:**
```bash
python --version    # Should be 3.8+
node --version      # Should be 16+
npm --version       # Should be 8+
```

### 2. Python Backend Setup

```bash
# Navigate to backend directory
cd backend

# Create a virtual environment
python -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate
# On Windows:
# venv\Scripts\activate

# Install Python dependencies
pip install -r requirements.txt
pip install -r requirements-test.txt

# Set up the database
python -c "from app import create_app; from plosolver_core.models import db; app = create_app(); app.app_context().push(); db.create_all()"
```

### 3. Frontend Setup

```bash
# Return to root directory
cd ..

# Install Node.js dependencies
npm install

# Build the frontend (optional, for production)
npm run build
```

### 4. Environment Configuration

```bash
# Copy environment template
cp env.development .env

# Edit .env file with your settings (optional)
nano .env
```

## 🏃‍♂️ Running the Application

### Development Mode (Recommended)
```bash
make run
```

This starts both frontend and backend in development mode:
- Frontend: http://localhost:3000
- Backend: http://localhost:5001

### Production Mode
```bash
make build
make run-docker
```

### With Docker
```bash
make run-docker
```

## 🔍 Verification

Check that everything is working:

```bash
# Run health check
make health

# Run quick tests
make test-quick
```

## 🚨 Troubleshooting

### Common Issues

**Port 5001 already in use:**
```bash
# Find and kill the process using port 5001
lsof -ti:5001 | xargs kill -9

# Or change the port in your .env file
echo "FLASK_PORT=5002" >> .env
```

**Python virtual environment issues:**
```bash
# Remove and recreate virtual environment
rm -rf src/backend/venv
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**Node.js dependency issues:**
```bash
# Clear npm cache and reinstall
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
```

**Database issues:**
```bash
# Reset the database
make db-reset
```

### Getting Help

If you're still having issues:

1. **Check the logs:**
   ```bash
   make debug-logs
   ```

2. **Run diagnostics:**
   ```bash
   make check-docker
   make health
   ```

3. **Create an issue:** [GitHub Issues](https://github.com/your-repo/issues)

## 🎯 Next Steps

Once you have PLOSolver running:

1. **Explore the Interface** - Navigate to http://localhost:3000
2. **Try Spot Mode** - Analyze your first poker situation
3. **Read the User Guide** - Learn about all features
4. **Join the Community** - Connect with other users

## 🔄 Updating

To update PLOSolver to the latest version:

```bash
# Pull latest changes
git pull origin main

# Update dependencies
make deps

# Restart the application
make run
```

---

**Need help?** Join our [Discord community](https://discord.gg/plosolver) or check the [FAQ](2024-01-01-faq.md). 