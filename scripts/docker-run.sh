#!/usr/bin/env bash
set -euo pipefail

echo "==> Starting MuchTodo stack with docker-compose..."
docker compose up --build -d

echo ""
echo "==> Waiting for services to become healthy..."
sleep 5
docker compose ps

echo ""
echo "✅ Stack is up."
echo "    Backend API : http://localhost:8080"
echo "    Health check: http://localhost:8080/health"
echo "    MongoDB     : localhost:27017"