# Self-Hosted GitHub Actions Runner Setup

This guide explains how to set up a self-hosted GitHub Actions runner locally to test CI pipelines without consuming GitHub-hosted runner minutes.

## 🎯 **Benefits**

- ✅ **No GitHub minutes consumed** - Run CI locally
- ✅ **Faster feedback** - No queue waiting
- ✅ **Cost savings** - Reduce GitHub Actions costs
- ✅ **Offline testing** - Test CI changes before pushing
- ✅ **Custom environment** - Use your local setup

## 📋 **Prerequisites**

### **System Requirements**
- macOS, Linux, or Windows
- Git installed
- Access to your GitHub repository
- At least 4GB RAM (8GB recommended)
- 10GB free disk space

### **Required Software**
- **Docker** - For container-based tests
- **Node.js** (v18+) - For frontend tests
- **Python** (v3.11+) - For backend tests
- **curl** - For downloading runner
- **jq** - For JSON processing

## 🚀 **Quick Setup (macOS)**

### **1. Install Dependencies**
```bash
# Install using Homebrew
brew install curl jq

# Install Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop

# Install Node.js
# Download from: https://nodejs.org/

# Install Python
# Download from: https://www.python.org/downloads/
```

### **2. Run Setup Script**
```bash
# Make script executable
chmod +x scripts/setup/setup-self-hosted-runner-macos.sh

# Install runner
./scripts/setup/setup-self-hosted-runner-macos.sh --install

# Configure runner (requires token)
./scripts/setup/setup-self-hosted-runner-macos.sh --configure

# Start runner
./scripts/setup/setup-self-hosted-runner-macos.sh --start
```

## 🔧 **Manual Setup**

### **Step 1: Get Runner Token**

1. Go to your GitHub repository
2. Navigate to **Settings** → **Actions** → **Runners**
3. Click **"New self-hosted runner"**
4. Copy the token from the configuration command

**Alternative using GitHub CLI:**
```bash
gh api repos/:owner/:repo/actions/runners/token --method POST
```

### **Step 2: Download and Install Runner**

```bash
# Create runner directory
mkdir ~/actions-runner && cd ~/actions-runner

# Download runner (macOS)
curl -o actions-runner-osx-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-osx-x64-2.311.0.tar.gz

# Extract runner
tar xzf ./actions-runner-osx-x64-2.311.0.tar.gz

# Clean up
rm actions-runner-osx-x64-2.311.0.tar.gz
```

### **Step 3: Configure Runner**

```bash
# Configure with your token
./config.sh --url https://github.com/PLOScope/plo-solver --token YOUR_TOKEN --unattended --replace
```

### **Step 4: Start Runner**

```bash
# Start manually
./run.sh

# Or install as service
./svc.sh install $USER
./svc.sh start
```

## 🎮 **Using the Runner**

### **Check Status**
```bash
./scripts/setup/setup-self-hosted-runner-macos.sh --status
```

### **Stop Runner**
```bash
./scripts/setup/setup-self-hosted-runner-macos.sh --stop
```

### **Remove Runner**
```bash
./scripts/setup/setup-self-hosted-runner-macos.sh --remove
```

## 🔄 **Testing CI Pipeline**

### **1. Trigger Workflow**
```bash
# Push to trigger CI
git push origin your-branch

# Or use workflow_dispatch (if configured)
# Go to Actions tab → Select workflow → Run workflow
```

### **2. Monitor Runner**
```bash
# Check runner status
./scripts/setup/setup-self-hosted-runner-macos.sh --status

# View logs
tail -f ~/actions-runner/_diag/*.log
```

### **3. View Workflow Results**
- Go to **Actions** tab in GitHub
- Click on the workflow run
- View detailed logs and results

## 🛠️ **Troubleshooting**

### **Common Issues**

#### **Runner Not Starting**
```bash
# Check if runner is configured
ls -la ~/actions-runner/.runner

# Check service status
./scripts/setup/setup-self-hosted-runner-macos.sh --status

# View error logs
tail -f ~/actions-runner/_diag/*.log
```

#### **Docker Issues**
```bash
# Ensure Docker is running
docker ps

# Check Docker permissions
docker run hello-world
```

#### **Permission Issues**
```bash
# Fix file permissions
chmod +x ~/actions-runner/*.sh

# Check user permissions
ls -la ~/actions-runner/
```

#### **Network Issues**
```bash
# Test GitHub connectivity
curl -I https://github.com

# Check firewall settings
# Ensure ports 443 and 22 are open
```

### **Reset Runner**
```bash
# Stop and remove runner
./scripts/setup/setup-self-hosted-runner-macos.sh --remove

# Reinstall from scratch
./scripts/setup/setup-self-hosted-runner-macos.sh --install
./scripts/setup/setup-self-hosted-runner-macos.sh --configure
./scripts/setup/setup-self-hosted-runner-macos.sh --start
```

## 🔒 **Security Considerations**

### **Runner Security**
- ✅ **Token Security** - Keep runner token secure
- ✅ **Network Access** - Limit runner network access
- ✅ **File Permissions** - Restrict file access
- ✅ **Service Account** - Use dedicated user account

### **Best Practices**
```bash
# Use dedicated user for runner
sudo useradd -m -s /bin/bash github-runner
sudo usermod -aG docker github-runner

# Set proper permissions
sudo chown -R github-runner:github-runner ~/actions-runner
```

## 📊 **Monitoring and Maintenance**

### **Log Locations**
```bash
# Runner logs
~/actions-runner/_diag/

# Workflow logs
~/actions-runner/_work/

# Service logs (macOS)
log show --predicate 'process == "github.actions.runner"' --last 1h
```

### **Cleanup**
```bash
# Clean old workflow files
rm -rf ~/actions-runner/_work/*/_

# Clean old logs
find ~/actions-runner/_diag/ -name "*.log" -mtime +7 -delete
```

## 🎯 **Advanced Configuration**

### **Runner Labels**
```bash
# Add custom labels during configuration
./config.sh --url https://github.com/PLOScope/plo-solver --token YOUR_TOKEN --labels "self-hosted,macOS,local" --unattended --replace
```

### **Environment Variables**
```bash
# Set runner environment variables
export RUNNER_OS="macOS"
export RUNNER_ARCH="X64"
export RUNNER_TEMP="$HOME/actions-runner/_work/_temp"
export RUNNER_TOOL_CACHE="$HOME/actions-runner/_work/_tool"
```

### **Multiple Runners**
```bash
# Create multiple runner instances
mkdir ~/actions-runner-1
mkdir ~/actions-runner-2

# Configure each with different names
./config.sh --url https://github.com/PLOScope/plo-solver --token TOKEN1 --name "runner-1" --unattended --replace
./config.sh --url https://github.com/PLOScope/plo-solver --token TOKEN2 --name "runner-2" --unattended --replace
```

## 📚 **Additional Resources**

- [GitHub Actions Runner Documentation](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Runner Installation Guide](https://docs.github.com/en/actions/hosting-your-own-runners/using-self-hosted-runners-in-a-workflow)
- [Runner Security](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners#self-hosted-runner-security)
- [Runner Troubleshooting](https://docs.github.com/en/actions/hosting-your-own-runners/using-self-hosted-runners-in-a-workflow#troubleshooting)

## 🆘 **Support**

If you encounter issues:

1. Check the troubleshooting section above
2. Review runner logs in `~/actions-runner/_diag/`
3. Check GitHub Actions documentation
4. Create an issue in the repository

---

**Happy CI Testing! 🚀** 