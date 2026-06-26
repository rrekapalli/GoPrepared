---
name: goprepared-content-generate
description: Modify offline Python content generators. Update contracts/ai first.
---

# Content Generate Skill

1. Update `contracts/ai/` if shapes change
2. Edit generators in `go-prepared-content/goprepared_content/generators/`
3. Run `scripts/generate-content.ps1`
4. Restart API to re-import (or truncate content_templates)
