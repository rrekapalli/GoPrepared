---
name: goprepared-journey-e2e
description: Debug end-to-end journey generation flow.
---

# Journey E2E Skill

```powershell
# Auth
$r = Invoke-RestMethod -Method POST -Uri http://localhost:8080/api/v1/auth/dev -ContentType application/json -Body '{"email":"e2e@test.com","name":"E2E"}'
$h = @{ Authorization = "Bearer $($r.accessToken)" }

# Create + generate
$j = Invoke-RestMethod -Method POST -Uri http://localhost:8080/api/v1/journeys -Headers $h -ContentType application/json -Body '{"query":"Vacation to Bali"}'
Invoke-RestMethod -Method POST -Uri "http://localhost:8080/api/v1/journeys/$($j.id)/generate" -Headers $h
Invoke-RestMethod -Uri "http://localhost:8080/api/v1/journeys/$($j.id)/cards" -Headers $h
```
