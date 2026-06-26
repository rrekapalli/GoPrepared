# Local Development

## Prerequisites

- Docker Desktop
- Java 21+
- Flutter 3.x
- Python 3.11+

## Bootstrap

```powershell
# 1. Optional local infra (Postgres + Ollama via Docker)
.\scripts\dev-up.ps1

# 2. Static content
.\scripts\generate-content.ps1

# 3. API (imports content on first run)
cd go-prepared-api
.\mvnw.cmd spring-boot:run

# 4. Flutter
cd go-prepared-app
flutter run -d chrome
```

## Dev auth

```powershell
curl -X POST http://localhost:8080/api/v1/auth/dev -H "Content-Type: application/json" -d "{\"email\":\"dev@test.com\",\"name\":\"Dev\"}"
```

## Ollama (optional)

Spring AI uses Ollama when available. With `goprepared.ai.fallback-to-static=true` (default), the API works without Ollama using imported templates.

```powershell
docker exec goprepared-ollama ollama pull llama3.2
```

## Proxmox deploy

For production on your Proxmox host, see [deployment/README.md](../deployment/README.md). Uses Tailscale-hosted Postgres and Ollama from `.env`.
