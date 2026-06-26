# GoPrepared

**Be Ready Anywhere** — AI-powered preparation intelligence for trips, events, health procedures, exams, and life milestones.

## Monorepo structure

| Project | Purpose |
|---------|---------|
| [go-prepared-app](go-prepared-app/) | Flutter app (Android, iOS, Web PWA) |
| [go-prepared-api](go-prepared-api/) | Spring Boot 3 + Spring AI (runtime inference) |
| [go-prepared-content](go-prepared-content/) | Python offline static content generator (CLI) |
| [contracts](contracts/) | JSON Schema for AI output types |
| [Docs](Docs/) | Architecture, API, and dev guides |
| [deployment](deployment/) | Proxmox LXC deploy; optional local Docker infra |

## Quick start (local dev)

1. Copy `.env.example` to `.env` and adjust values.
2. Start infrastructure:

   ```powershell
   .\scripts\dev-up.ps1
   ```

3. Generate and import static content:

   ```powershell
   .\scripts\generate-content.ps1
   .\scripts\import-content.ps1
   ```

4. Run the API (from `go-prepared-api/`):

   ```powershell
   .\mvnw.cmd spring-boot:run
   ```

5. Run the Flutter app (from `go-prepared-app/`):

   ```powershell
   flutter pub get
   flutter run -d chrome
   ```

See [Docs/local-dev.md](Docs/local-dev.md) for full setup.

## Deploy (Proxmox LXC)

Production deploy uses **Proxmox LXC** (not Docker). See [deployment/README.md](deployment/README.md).

```bash
cp .env.example .env   # configure Proxmox, Tailscale, Postgres, Ollama
./deploy.sh
```

## Architecture

- **User requests** → Flutter → Spring Boot + Spring AI + RAG (static content from DB)
- **Content refresh** → Python CLI → `output/` → import script → PostgreSQL

Python is **not** called at request time.

## Cursor development

See [AGENTS.md](AGENTS.md) and [.cursor/rules](.cursor/rules/) for project conventions.
