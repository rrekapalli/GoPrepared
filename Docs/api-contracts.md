# GoPrepared REST API

Base URL: `http://localhost:8080/api/v1`

OpenAPI: `http://localhost:8080/swagger-ui.html`

## Auth

| Method | Path | Auth | Body |
|--------|------|------|------|
| POST | `/auth/dev` | — | `{ "email", "name?" }` |
| POST | `/auth/google` | — | `{ "idToken" }` |
| GET | `/users/me` | Bearer JWT | — |

**Response (auth):** `{ "accessToken", "user": { "id", "name", "email", "profilePicture" } }`

## Journeys

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/journeys` | JWT | Create journey from natural-language query (classifies via Spring AI) |
| POST | `/journeys/{id}/generate` | JWT | Generate preparation cards |
| GET | `/journeys` | JWT | List user journeys |
| GET | `/journeys/{id}` | JWT | Journey detail |
| GET | `/journeys/{id}/status` | JWT | Progress: cards viewed, checklist completion |
| GET | `/journeys/{id}/cards` | JWT | Card summaries (no detail) |
| POST | `/journeys/{id}/ask` | JWT | Ask about the whole journey `{ "question" }` |

## Cards

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/cards/{id}` | JWT | Card detail (lazy AI expansion on first view) |
| POST | `/cards/{id}/ask` | JWT | Ask about a specific card `{ "question" }` |

## Checklist

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/journeys/{id}/checklist` | JWT | Get or generate checklist for journey |
| POST | `/checklist/{id}/complete` | JWT | Toggle checklist item completion |

## Knowledge (public read)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/knowledge/categories` | — | Category tiles with journey counts |
| GET | `/knowledge/nodes` | — | Knowledge graph nodes (imported static content) |
| GET | `/knowledge/relationships` | — | Graph edges (`sourceName`, `targetName`, `relationshipType`) |

## Community

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/community` | — | Featured community insights |
| POST | `/community/contribute` | JWT | Submit insight |
| POST | `/community/vote` | JWT | Vote on insight `{ "insightId", "helpful" }` |

## Errors

All errors return:

```json
{ "error": "not_found", "message": "Journey not found", "timestamp": "2026-06-26T12:00:00Z" }
```

Common `error` values: `not_found`, `validation_error`, `bad_request`, `forbidden`, `internal_error`.

## Static content import

On startup (when DB is empty), the API imports from `go-prepared-content/output/`:

- `journey-templates/*.json` → content templates for RAG
- `knowledge/graph.json` → nodes + edges
- `community/featured.json` → seed insights

Regenerate content: `python -m goprepared_content.cli all` from `go-prepared-content/`.

See [ai-contracts.md](ai-contracts.md) for AI payload shapes.
