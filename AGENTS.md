# GoPrepared — Cursor Agent Entry

Be Ready Anywhere. Monorepo: Flutter app + Spring Boot/Spring AI API + Python offline content generator.

## Load skills

| Task | Skill |
|------|-------|
| Flutter screens | `.cursor/skills/goprepared-flutter-feature/` |
| REST + Spring AI | `.cursor/skills/goprepared-api-endpoint/` |
| Python content seeds | `.cursor/skills/goprepared-content-generate/` |
| Spring AI workflows | `.cursor/skills/goprepared-ai-workflow/` |
| Local dev | `.cursor/skills/goprepared-local-dev/` |
| E2E debugging | `.cursor/skills/goprepared-journey-e2e/` |

## Key docs

- [Docs/architecture.md](Docs/architecture.md) — **Python is batch-only; Spring AI handles runtime inference**
- [Docs/api-contracts.md](Docs/api-contracts.md)
- [Docs/ai-contracts.md](Docs/ai-contracts.md)
- [contracts/ai/](contracts/ai/) — JSON Schema source of truth

## Commands

```powershell
.\scripts\dev-up.ps1
.\scripts\generate-content.ps1
cd go-prepared-api; .\mvnw.cmd spring-boot:run
cd go-prepared-app; flutter run -d chrome
```

## Rules

See [.cursor/rules/](.cursor/rules/) — especially `ai-contracts.mdc` and `goprepared-monorepo.mdc`.
