---
name: goprepared-api-endpoint
description: Add REST endpoints, Flyway migrations, and Spring AI workflow wiring in go-prepared-api.
---

# API Endpoint Skill

1. Update `Docs/api-contracts.md`
2. Add controller method in `ApiController`
3. Flyway migration if schema changes
4. Wire Spring AI workflow in `service/` layer
5. Verify: `.\mvnw.cmd compile` (Windows) or `./mvnw compile` (Unix) && curl test
