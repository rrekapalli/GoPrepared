# GoPrepared Architecture

## Runtime vs batch

| Component | Role | Called at request time? |
|-----------|------|-------------------------|
| go-prepared-app | Flutter UI | Yes |
| go-prepared-api + Spring AI | Auth, REST, inference, RAG | Yes |
| go-prepared-content | Static JSON generator (CLI) | **No** |

## Data flow

1. `goprepared_content.cli` generates JSON → `go-prepared-content/output/`
2. API `ContentImportConfig` loads seeds into PostgreSQL on first startup
3. User query → Spring AI + `StaticContentRetrievalService` → structured JSON contracts → DB

## Contracts

All AI outputs use types in [contracts/ai/](../contracts/ai/).
