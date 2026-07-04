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

# 4. Flutter (web)
cd go-prepared-app
..\scripts\flutter-run-web.ps1
```

Or, if `flutter run -d chrome` is already running, **stop it first** (`q`) — hot restart does not reload patched engine code.

```powershell
.\scripts\patch-flutter-web-context-lost.ps1
.\scripts\flutter-run-web.ps1
```

### Flutter web dev notes

On `localhost`, PWA version polling is disabled so hot reload/restart is not fighting cache updates.

If hot restart logs `LateInitializationError: _handledContextLostEvent`, apply the one-time engine patch (stable 3.44.x is missing [flutter#184683](https://github.com/flutter/flutter/issues/184683)):

```powershell
.\scripts\patch-flutter-web-context-lost.ps1
```

Then restart `flutter run -d chrome`. Re-run the patch after `flutter upgrade` if the error returns.

## WSL (Ubuntu 24.04) — deploy & Linux tooling

Same pattern as purana-samhitha and MoneyTree: use **Ubuntu 24.04** as the default WSL distro for `./deploy.sh`, not Fedora `podman-local`.

**One-time setup (Windows):**

```powershell
powershell -File scripts/setup-wsl.ps1
```

This sets `Ubuntu-24.04` as default WSL, installs Java 21, Maven, `sshpass`, `zip`, `jq`, Python venv tools, and normalizes shell script line endings.

**Manual setup (inside WSL):**

```bash
cd /mnt/c/vislesha/code/personal/GoPrepared
./deployment/prepare-dev-machine.sh
```

**Deploy from WSL:**

```bash
./deploy.sh                  # build + deploy (API via Maven in WSL; PWA via Windows Flutter if needed)
./deploy.sh --skip-build     # deploy existing artifacts
```

**Windows Flutter from WSL:** build the PWA on Windows first, then deploy:

```powershell
powershell -File scripts/build_pwa_artifact.ps1
```

```bash
./deploy.sh --skip-build
```

Cursor opens an **Ubuntu-24.04** terminal at the repo root (see `.vscode/settings.json`).

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
