# PLO Solver - ngrok Setup Guide

This guide explains how to use ngrok to expose your PLO Solver app to the internet for testing and sharing.

## 🚀 Quick Start

### Method 1: Using the Helper Script (Recommended)

1. **Get your ngrok URL first:**
   ```bash
   ngrok http 80
   ```

2. **Copy the ngrok URL** (e.g., `https://abc123.ngrok-free.app`)

3. **Use the helper script:**
   ```bash
   ./start-ngrok.sh https://abc123.ngrok-free.app
   ```

4. **The script will:**
   - Configure environment for Traefik + ngrok
   - Start all services with Docker Compose
   - Set up proper routing through Traefik

5. **Access your app** via the ngrok URL!

### Method 2: Manual Setup

1. **Set up environment for your ngrok domain:**
   ```bash
   # Replace with your actual ngrok domain
   export FRONTEND_DOMAIN=abc123.ngrok-free.app
   export REACT_APP_API_URL=/api
   ```

2. **Start services with Docker Compose:**
   ```bash
   # Start Traefik + all services
   docker compose -f docker-compose.yml -f docker compose.ngrok.yml up -d
   
   # In another terminal, start ngrok
   ngrok http 80
   ```

3. **Access via ngrok URL**

## 🔧 What Was Fixed

### The Problem
When using ngrok, the frontend was making API calls to `http://localhost:5001` instead of going through the ngrok tunnel, causing CORS and connectivity issues.

### The Solution
1. **Smart API URL Detection:** The app now automatically detects if it's running through ngrok and uses relative URLs
2. **Webpack Configuration:** Updated to allow all hosts (fixes "Invalid Host header")
3. **Environment Variables:** Proper configuration for different deployment scenarios

### Code Changes Made
```javascript
// Before (hardcoded localhost)
const API_URL = 'http://localhost:5001';

// After (smart detection)
const API_URL = process.env.REACT_APP_API_URL || (
  window.location.hostname === 'localhost' ? 'http://localhost:5001' : ''
);
```

## 🌐 How It Works

### Local Development (localhost)
- **Frontend:** http://localhost:3000
- **Backend:** http://localhost:5001
- **API Calls:** Direct to `http://localhost:5001`

### ngrok Tunnel
- **Frontend:** https://abc123.ngrok-free.app
- **Backend:** Proxied through ngrok tunnel
- **API Calls:** Relative URLs (e.g., `/auth/login`)

## 📋 Step-by-Step Setup

### 1. Install ngrok
```bash
# macOS
brew install ngrok

# Or download from https://ngrok.com/download
```

### 2. Setup ngrok Account (Optional but Recommended)
```bash
# Sign up at https://ngrok.com and get your auth token
ngrok config add-authtoken YOUR_AUTH_TOKEN
```

### 3. Start Backend Server
```bash
cd backend
python equity_server.py
```
You should see: `Server is up on localhost:5001`

### 4. Start Frontend (Choose One Method)

#### Option A: Using Helper Script
```bash
# Start ngrok first
ngrok http 3000

# Copy the https URL and use it with the script
./start-ngrok.sh https://your-ngrok-url.ngrok-free.app
```

#### Option B: Manual Setup
```bash
# Set environment for ngrok
export REACT_APP_API_URL=""

# Start frontend
npm run start:ngrok

# In another terminal, start ngrok
ngrok http 3000
```

### 5. Access Your App
- **Local:** http://localhost:3000
- **ngrok:** https://your-ngrok-url.ngrok-free.app

## 🔒 Security Considerations

### ngrok Free Tier Limitations
- URLs change each time you restart ngrok
- Limited to 1 tunnel at a time
- No custom domains

### For Production Use
Consider upgrading to ngrok Pro for:
- Custom domains
- Reserved URLs
- Multiple tunnels
- Better security

## 🛠 Troubleshooting

### Common Issues

1. **"Invalid Host header"**
   - ✅ **Fixed:** Webpack config updated with `allowedHosts: 'all'`

2. **API calls to localhost failing**
   - ✅ **Fixed:** Smart URL detection implemented

3. **CORS errors**
   - ✅ **Fixed:** Using relative URLs eliminates CORS issues

4. **Login not working**
   - ✅ **Fixed:** Auth API now uses relative URLs

### Debug Steps

1. **Check if backend is running:**
   ```bash
   curl http://localhost:5001/health
   ```

2. **Check if frontend is accessible:**
   ```bash
   curl http://localhost:3000
   ```

3. **Test ngrok tunnel:**
   ```bash
   curl https://your-ngrok-url.ngrok-free.app/health
   ```

4. **Check API calls in browser:**
   - Open Developer Tools → Network tab
   - Look for API calls - they should go to relative URLs

### Logs to Check
```bash
# Backend logs
tail -f backend/equity_server.log

# Frontend logs
# Check browser console for errors

# ngrok logs
# Check ngrok terminal for request logs
```

## 🚀 Advanced Usage

### Custom ngrok Configuration
Create `ngrok.yml`:
```yaml
version: "2"
authtoken: YOUR_AUTH_TOKEN
tunnels:
  plosolver:
    addr: 3000
    proto: http
    hostname: your-custom-domain.ngrok.io
```

Start with: `ngrok start plosolver`

### Multiple Environments
```bash
# Development
./start-ngrok.sh https://dev-abc123.ngrok-free.app

# Testing
./start-ngrok.sh https://test-xyz789.ngrok-free.app
```

### Backend Tunneling (If Needed)
If you need to expose the backend separately:
```bash
# Terminal 1: Backend tunnel
ngrok http 5001

# Terminal 2: Frontend tunnel  
ngrok http 3000

# Update environment
export REACT_APP_API_URL="https://backend-ngrok-url.ngrok-free.app"
```

## 📱 Mobile Testing

ngrok is perfect for testing on mobile devices:

1. **Start ngrok tunnel**
2. **Share the ngrok URL** with your mobile device
3. **Test the app** on different devices and browsers

## 🔄 Automation Scripts

### Auto-restart Script
```bash
#!/bin/bash
# auto-ngrok.sh
while true; do
    echo "Starting ngrok..."
    ngrok http 3000
    echo "ngrok stopped, restarting in 5 seconds..."
    sleep 5
done
```

### Full Stack Startup
```bash
#!/bin/bash
# start-all.sh
echo "Starting PLO Solver with ngrok..."

# Start backend
cd backend && python equity_server.py &
BACKEND_PID=$!

# Wait for backend to start
sleep 3

# Start frontend
cd .. && npm run start:ngrok &
FRONTEND_PID=$!

# Wait for frontend to start
sleep 5

# Start ngrok
ngrok http 3000 &
NGROK_PID=$!

echo "All services started!"
echo "Backend PID: $BACKEND_PID"
echo "Frontend PID: $FRONTEND_PID"
echo "ngrok PID: $NGROK_PID"

# Cleanup on exit
trap "kill $BACKEND_PID $FRONTEND_PID $NGROK_PID" EXIT
wait
```

## 📞 Support

If you encounter issues:

1. **Check the logs** in all terminals
2. **Verify environment variables:** `echo $REACT_APP_API_URL`
3. **Test local access first:** http://localhost:3000
4. **Check ngrok status:** Visit http://localhost:4040 (ngrok dashboard)

## 🎯 Summary

The ngrok setup is now fully configured and should work seamlessly:

- ✅ **No more "Invalid Host header" errors**
- ✅ **API calls work through ngrok tunnel**
- ✅ **Login and authentication functional**
- ✅ **All features accessible via ngrok URL**
- ✅ **Easy setup with helper scripts**

**Happy PLO Solving from anywhere! 🃏🌐** 