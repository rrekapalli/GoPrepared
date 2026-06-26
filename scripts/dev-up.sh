#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../deployment/docker"
docker compose up -d postgres ollama
echo "Run: docker exec goprepared-ollama ollama pull llama3.2"
