# Beta Launch Readiness

Checklist for GoPrepared beta on Proxmox LXC + Tailscale.

## App (Flutter)

- [x] Discover: query bar, example chips, feature cards, explore banner
- [x] Journey creation → deck flow wired to API
- [x] Deck: stacked cards, journey title, checklist shortcut
- [x] Card detail: dos/donts, weather, currency, emergency contacts, ask bar
- [x] Journeys: dark theme, search, filters, progress, thumbnails
- [x] Checklist: API-backed toggle + completion %
- [x] Knowledge: categories + preparation path from graph edges
- [x] Community: list, contribute, vote
- [x] Profile: real stats from API, notification toggles
- [x] Bottom nav styled per mockups (blue active pill)

## API

- [x] Full REST layer (auth, journeys, cards, checklist, knowledge, community)
- [x] CORS for localhost + `goprepared.*` tailnet hosts

## Deploy

- [x] Proxmox LXC (`./deploy.sh`)
- [x] nginx PWA + `/api/` proxy

## Pre-beta smoke test

```bash
# 1. Content + API locally or on LXC
python -m goprepared_content.cli all
./deploy.sh   # or local mvnw + flutter run

# 2. Dev auth
curl -X POST http://localhost:8080/api/v1/auth/dev \
  -H "Content-Type: application/json" \
  -d '{"email":"beta@test.com","name":"Beta"}'

# 3. Create journey
curl -X POST http://localhost:8080/api/v1/journeys \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"query":"Vacation to Bali"}'
```

## Known beta limitations

- Google + Microsoft OAuth with hybrid access (Explore public; journeys require sign-in). See [Docs/oauth-setup.md](oauth-setup.md).
- Map "Explore Map" button is placeholder
- Notification toggles are local-only (no push yet)
- Profile impact score is computed client-side from journey status
