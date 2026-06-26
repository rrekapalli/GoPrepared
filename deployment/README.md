# GoPrepared Deployment

Deploy the Flutter PWA (nginx) and Spring Boot API to a single Proxmox LXC container **goprepared** (VMID **7003**), joined to your Tailscale tailnet.

Pattern follows [purana-samhitha/deployment](https://github.com/rrekapalli/purana-samhitha/tree/master/deployment).

## Layout

```
deploy.sh                     # build + deploy (default)
deployment/
├── prepare-artifacts.sh      # build PWA zip + API jar
├── build-and-deploy.sh       # forwards to ../deploy.sh
├── deploy-all.sh             # forwards to ../deploy.sh
├── artifacts/                # built outputs (gitignored)
├── docker/                   # optional local dev (Postgres + Ollama)
└── proxmox/
    ├── deployment.conf       # VMID, hostname, ports, clone template
    ├── deploy-lxc.sh         # full stack (API + PWA)
    ├── deploy-api.sh         # Spring Boot systemd service
    ├── deploy-ui.sh          # nginx static PWA + /api proxy
    ├── join-tailscale.sh
    ├── add-lxc-to-tailscale.sh
    ├── remove-lxc-from-tailscale.sh
    ├── diagnose.sh
    ├── nginx/goprepared.conf.template
    └── lib/                  # shared Proxmox helpers
```

Workspace secrets live in the repo root **`.env`** (see `.env.example`).

## Prerequisites

1. Proxmox host with `pct` (run on host, or set `PROXMOX_*` in `.env` for remote SSH from WSL).
2. LXC clone template **`moneytree-lxc-base`** (VMID 9001) — SSH, Tailscale package, user `raja`.
3. **Flutter** + **Java 21** + **Maven** on the build machine (or WSL with `powershell.exe` for Windows Flutter).
4. **PostgreSQL** and **Ollama** reachable on Tailscale (defaults in `.env`: `pg18.*`, `ollama.*`).
5. Copy `.env.example` → `.env` and set `CONTAINER_PASSWORD`, `PROXMOX_PASSWORD`, `TS_AUTHKEY`, DB credentials.

Generate static content before first API deploy (imported on startup):

```bash
cd go-prepared-content && python -m goprepared_content.cli all
```

## Runtime architecture (single LXC)

| Service | Port | Role |
|---------|------|------|
| nginx | 80 | Flutter PWA + reverse proxy `/api/` → Spring Boot |
| goprepared-api | 8080 | Spring Boot (systemd, localhost only) |

External (Tailscale):

| Service | Role |
|---------|------|
| PostgreSQL (`POSTGRES_HOST`) | Primary database |
| Ollama (`OLLAMA_BASE_URL`) | Spring AI inference |

## Quick start

```bash
# From repo root (Git Bash / WSL / Linux)
cp .env.example .env   # edit secrets

# Build + deploy full stack
./deploy.sh

# Deploy existing artifacts only
./deploy.sh --skip-build

# Recreate LXC from template
./deploy.sh --recreate
```

**Windows Flutter from WSL:** build on Windows first, then deploy:

```powershell
powershell -File scripts/build_pwa_artifact.ps1
cd go-prepared-api; .\mvnw.cmd -DskipTests package
# copy jar to deployment/artifacts/go-prepared-api.jar if needed
```

```bash
./deploy.sh --skip-build
```

## Tailscale (MagicDNS)

```bash
./deployment/proxmox/join-tailscale.sh
./deployment/proxmox/diagnose.sh
```

Once joined:

- **PWA:** `http://goprepared.<your-tailnet>/`
- **API:** `http://goprepared.<your-tailnet>/api/v1/`

## Options

```bash
./deploy.sh --api-only
./deploy.sh --ui-only
./deploy.sh --recreate --skip-build
```

## Configuration

- **`deployment/proxmox/deployment.conf`** — VMID 7003, memory, template name (non-secret).
- **`.env`** — Proxmox, Tailscale, Postgres, Ollama, JWT, `GOPREPARED_HOST`.

## Local dev (optional Docker)

For local development only (not production deploy):

```powershell
.\scripts\dev-up.ps1   # uses deployment/docker/docker-compose.yml
```

## Troubleshooting

```bash
./deployment/proxmox/diagnose.sh
./deployment/proxmox/join-tailscale.sh
./deploy.sh --skip-build
```

On Proxmox host:

```bash
pct exec 7003 -- systemctl status goprepared-api nginx
pct exec 7003 -- journalctl -u goprepared-api -n 80 --no-pager
pct exec 7003 -- curl -sI http://127.0.0.1/api/v1/knowledge/categories
```
