# Deploy to DigitalOcean

One command takes a fresh Ubuntu 24.04 droplet from zero to a running, TLS-terminated OpenClaw instance with an agent team deployed.

## Prerequisites

- A DigitalOcean account
- An SSH key added to your DO account
- ~5 minutes

## Quick Start

### 1. Create a Droplet

1. Go to [DigitalOcean](https://cloud.digitalocean.com)
2. Create a new **Ubuntu 24.04** droplet with your SSH key:
   - **Minimum:** 2GB RAM, 2 vCPU ($12/month)
   - **Production:** 8GB RAM, 4 vCPU
3. Note the droplet's IP address

### 2. SSH in and Run

```bash
ssh root@YOUR_DROPLET_IP
```

Then run the one-liner for your team:

```bash
curl -fsSL https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main/bootstrap.sh \
  | bash -s -- --team product-builder
```

That's it. The script handles everything: server hardening, Node.js, OpenClaw, team deployment, TLS, and systemd.

## Options

```bash
curl -fsSL https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main/bootstrap.sh \
  | bash -s -- \
    --team product-builder \
    --user szewong \
    --key "ssh-ed25519 AAAA..." \
    --domain example.com \
    --api-key sk-ant-...
```

| Flag | Description | Default |
|------|-------------|---------|
| `--team <name>` | **Required.** Team to deploy | — |
| `--user <name>` | Admin SSH username | `zuser-XXXX` (random 4-digit) |
| `--key "<pubkey>"` | SSH public key override | Copies from root's `authorized_keys` |
| `--domain <fqdn>` | Domain for Let's Encrypt TLS | Self-signed via IP |
| `--api-key <key>` | Anthropic API key | Leave `.env` as template |

## Available Teams

| Team | Flag |
|------|------|
| Product Builder | `--team product-builder` |
| Accountant | `--team accountant` |
| Recruiter | `--team recruiter` |
| Real Estate | `--team real-estate` |
| Modernizer | `--team modernizer` |
| Operator | `--team operator` |

## What It Does

The bootstrap script runs 5 phases:

1. **Server Hardening** — installs packages, creates an admin user with SSH key, configures UFW (ports 22/80/443), enables fail2ban
2. **OpenClaw Installation** — creates a `openclaw` system user, installs Node.js 22.x, installs OpenClaw, creates a systemd service
3. **Team Deployment** — clones this repo, runs the team's `setup.sh`, configures the API key
4. **Reverse Proxy** — installs Caddy, provisions TLS (Let's Encrypt with `--domain`, self-signed without), reverse proxies to the gateway
5. **Summary** — prints the admin username, access URL, SSH command, and next steps

## After Deployment

### Set your API key (if not passed via `--api-key`)

```bash
sudo -u openclaw nano /home/openclaw/.openclaw/.env
```

### Edit your vision

```bash
sudo -u openclaw nano /home/openclaw/.openclaw/shared/VISION.md
```

### Service management

```bash
sudo systemctl status openclaw-gateway
sudo systemctl restart openclaw-gateway
sudo journalctl -u openclaw-gateway -f
```

## Security

- **Admin user** (`zuser-XXXX` or custom): SSH access, sudo, system administration. Non-standard name deters brute-force bots.
- **`openclaw` system user**: no login shell, no SSH, no sudo — runs the gateway only.
- Root login is key-only (`PermitRootLogin prohibit-password`) for DO recovery.
- Password authentication is disabled.
- UFW allows only ports 22, 80, and 443.
- fail2ban protects SSH.

## Idempotency

The script is safe to run multiple times. Users are checked before creation, packages are idempotent, the systemd unit is overwritten and reloaded, and team setup scripts already handle existing installations.

## Troubleshooting

### Gateway isn't responding
```bash
sudo systemctl status openclaw-gateway
sudo journalctl -u openclaw-gateway --no-pager -n 50
```

### Can't SSH as admin user
The admin username is printed at the end of the bootstrap. If you lost it, check:
```bash
# From root:
ls /home/
```

### Want more control?
Edit the team's files to adjust agent behavior:
- `/home/openclaw/.openclaw/shared/VISION.md` — business context
- `/home/openclaw/.openclaw/workspace-*/SOUL.md` — agent personality
- `/home/openclaw/.openclaw/shared/skills/*` — agent capabilities

## Questions?

See the full documentation: https://docs.openclaw.ai
