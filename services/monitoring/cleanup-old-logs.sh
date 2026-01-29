#!/bin/bash

# Script to clean up old Docker log files that are causing Alloy startup issues
# This prevents Alloy from trying to read very old logs that Loki will reject

set -euo pipefail

echo "🧹 Starting cleanup of old Docker log files..."

# Try different possible Docker log directory locations
DOCKER_LOG_DIRS=(
    "/var/lib/docker/containers"
    "/var/snap/docker/common/var-lib-docker/containers"
    "/var/lib/docker/overlay2"
)

DOCKER_LOG_DIR=""
for dir in "${DOCKER_LOG_DIRS[@]}"; do
    if [ -d "$dir" ] && [ -r "$dir" ]; then
        DOCKER_LOG_DIR="$dir"
        echo "📁 Found Docker log directory: $DOCKER_LOG_DIR"
        break
    fi
done

# If no standard directory found, check Docker volumes and running containers
if [ -z "$DOCKER_LOG_DIR" ]; then
    echo "🔍 Checking Docker volumes and running containers for log files..."
    
    # Check if docker command is available
    if command -v docker >/dev/null 2>&1; then
        # Method 1: Check Docker volumes
        echo "📋 Checking Docker volumes..."
        VOLUME_NAMES=$(docker volume ls --format "{{.Name}}" 2>/dev/null || true)
        
        for volume_name in $VOLUME_NAMES; do
            # Get volume mount point
            VOLUME_PATH=$(docker volume inspect "$volume_name" --format "{{.Mountpoint}}" 2>/dev/null || true)
            if [ -n "$VOLUME_PATH" ] && [ -d "$VOLUME_PATH" ] && [ -r "$VOLUME_PATH" ]; then
                # Check if this volume contains container logs
                if find "$VOLUME_PATH" -name "*.log" -type f -mtime +7 2>/dev/null | head -1 | grep -q .; then
                    DOCKER_LOG_DIR="$VOLUME_PATH"
                    echo "📁 Found Docker volume '$volume_name' with old logs: $DOCKER_LOG_DIR"
                    break
                fi
            fi
        done
        
        # Method 2: Check running containers for log files
        if [ -z "$DOCKER_LOG_DIR" ]; then
            echo "📋 Checking running containers for log files..."
            CONTAINER_IDS=$(docker ps --format "{{.ID}}" 2>/dev/null || true)
            
            for container_id in $CONTAINER_IDS; do
                # Get container's log path
                LOG_PATH=$(docker inspect "$container_id" --format "{{.LogPath}}" 2>/dev/null || true)
                if [ -n "$LOG_PATH" ] && [ -f "$LOG_PATH" ] && [ -r "$LOG_PATH" ]; then
                    # Check if this log file is old
                    if [ "$(find "$LOG_PATH" -mtime +7 2>/dev/null | wc -l)" -gt 0 ]; then
                        DOCKER_LOG_DIR="$(dirname "$LOG_PATH")"
                        echo "📁 Found container logs directory: $DOCKER_LOG_DIR"
                        break
                    fi
                fi
            done
        fi
    else
        echo "⚠️  Docker command not available, cannot check volumes or containers"
    fi
fi

if [ -z "$DOCKER_LOG_DIR" ]; then
    echo "⚠️  Docker containers directory not found or not accessible"
    echo "📋 Tried locations:"
    for dir in "${DOCKER_LOG_DIRS[@]}"; do
        echo "   - $dir"
    done
    echo "📋 Also checked Docker volumes for old log files"
    echo "✅ Skipping cleanup - this is normal in some environments"
    exit 0
fi

# Count files before cleanup
OLD_LOG_COUNT=$(find "$DOCKER_LOG_DIR" -name "*.log" -type f -mtime +7 2>/dev/null | wc -l)
OLD_COMPRESSED_COUNT=$(find "$DOCKER_LOG_DIR" -name "*.log.*" -type f -mtime +7 2>/dev/null | wc -l)

echo "📊 Found $OLD_LOG_COUNT old log files and $OLD_COMPRESSED_COUNT compressed log files older than 7 days"

if [ "$OLD_LOG_COUNT" -eq 0 ] && [ "$OLD_COMPRESSED_COUNT" -eq 0 ]; then
    echo "✅ No old log files found. Nothing to clean up."
    exit 0
fi

# Find and remove Docker log files older than 7 days
echo "🗑️  Removing old Docker log files..."
find "$DOCKER_LOG_DIR" -name "*.log" -type f -mtime +7 -delete 2>/dev/null || {
    echo "⚠️  Some log files could not be deleted (may be in use)"
}

# Also clean up any compressed log files older than 7 days
echo "🗑️  Removing old compressed log files..."
find "$DOCKER_LOG_DIR" -name "*.log.*" -type f -mtime +7 -delete 2>/dev/null || {
    echo "⚠️  Some compressed log files could not be deleted (may be in use)"
}

# Additional cleanup: Use Docker system prune for container logs if available
if command -v docker >/dev/null 2>&1; then
    echo "🧹 Running Docker system cleanup for additional log cleanup..."
    docker system prune -f --filter "until=168h" 2>/dev/null || {
        echo "⚠️  Docker system prune failed (may require different permissions)"
    }
fi

# Count files after cleanup
NEW_LOG_COUNT=$(find "$DOCKER_LOG_DIR" -name "*.log" -type f -mtime +7 2>/dev/null | wc -l)
NEW_COMPRESSED_COUNT=$(find "$DOCKER_LOG_DIR" -name "*.log.*" -type f -mtime +7 2>/dev/null | wc -l)

echo "✅ Cleanup completed successfully!"
echo "📊 Removed $((OLD_LOG_COUNT - NEW_LOG_COUNT)) log files and $((OLD_COMPRESSED_COUNT - NEW_COMPRESSED_COUNT)) compressed files"
echo "🚀 Alloy should now start without timestamp errors."
