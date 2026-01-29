#!/bin/bash

echo "🚀 Starting PLO Solver with ngrok and Traefik..."

# Check if ngrok is running
if ! curl -s http://localhost:4040/api/tunnels &> /dev/null; then
    echo "⚠️  ngrok doesn't appear to be running. Starting ngrok on port 8080..."
    ngrok http 8080 &
    echo "⏳ Waiting for ngrok to start..."
    sleep 5
fi

# Get the ngrok URL
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$NGROK_URL" ]; then
    echo "❌ Could not get ngrok URL. Make sure ngrok is running with: ngrok http 8080"
    exit 1
fi

echo "✅ Found ngrok URL: $NGROK_URL"

# Check if --forum flag was passed
if [[ "$1" == "--forum" ]]; then
    echo "🗣️  Starting with forum support..."
    ./run_with_traefik.sh --ngrok "$NGROK_URL" --forum
else
    echo "🚀 Starting without forum..."
    ./run_with_traefik.sh --ngrok "$NGROK_URL"
fi 