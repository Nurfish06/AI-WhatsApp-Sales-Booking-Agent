#!/bin/bash
# AI WhatsApp Agent - Automated Deployment Script

set -e

echo "🚀 Starting Deployment Process..."

# 1. Pull latest code
echo "📦 Pulling latest code from git..."
git pull origin main

# 2. Rebuild and restart containers
echo "🐳 Restarting Docker containers..."
cd docker
docker-compose pull
docker-compose up -d --build

# 3. Prune old images to save space
echo "🧹 Cleaning up unused Docker images..."
docker image prune -f

echo "✅ Deployment completed successfully!"
