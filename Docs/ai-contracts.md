# AI JSON Contracts

Source of truth: [contracts/ai/](../contracts/ai/)

## Types

- **JourneyClassification** — classify user query
- **PreparationCard** — deck cards; `detail` for expanded content (Travel Info UI)
- **ChecklistItem** — checklist rows (MVP2)
- **KnowledgeNode** / **KnowledgeEdge** — knowledge graph (MVP3)
- **CommunityInsight** — tips, warnings, experiences (MVP4)

## Producers

| Type | Runtime (Spring AI) | Offline (Python CLI) |
|------|---------------------|----------------------|
| JourneyClassification | Yes | Template metadata |
| PreparationCard | Yes | Journey templates |
| ChecklistItem | Stub | Future |
| KnowledgeNode/Edge | Stub | Yes |
| CommunityInsight | Stub | Featured seeds |

## Example: PreparationCard.detail

```json
{
  "destinationLabel": "Bali, Indonesia",
  "dos": ["Dress modestly at temples"],
  "donts": ["Don't touch people's heads"],
  "currency": { "name": "IDR", "exchangeRateNote": "1 USD ≈ 15,500 IDR" },
  "weather": "Tropical, humid.",
  "emergencyContacts": [{ "label": "Police", "number": "110" }]
}
```
