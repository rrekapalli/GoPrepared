---
name: goprepared-ai-workflow
description: Add or modify Spring AI runtime workflows and prompts in go-prepared-api.
---

# Spring AI Workflow Skill

1. Add workflow class under `ai/workflows/`
2. Prompt template in `src/main/resources/prompts/`
3. Output must match `AiContracts` types
4. Fallback to `StaticContentRetrievalService` when Ollama unavailable
