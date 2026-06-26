# GoPrepared Contracts

JSON Schema Draft 2020-12 definitions in `ai/` are the single source of truth for structured AI outputs.

## Canonical types

- `JourneyClassification`
- `PreparationCard`
- `ChecklistItem`
- `KnowledgeNode`
- `KnowledgeEdge`
- `CommunityInsight`

## Regenerate bindings

```powershell
.\scripts\generate-contracts.ps1
```

```bash
./scripts/generate-contracts.sh
```

Updates Python (Pydantic), Java (records), and Flutter (manual sync via models in `go-prepared-app`).

## Rules

1. Update schema first, then regenerate bindings.
2. Runtime inference (Spring AI) and offline generation (Python CLI) must both conform.
3. No markdown persisted in `card_details.content` — use `PreparationCard.detail` JSON.
