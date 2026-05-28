# Deploy to DigitalOcean

Three steps take a fresh Ubuntu 24.04 droplet from zero to a running, TLS-terminated OpenClaw instance with an agent team deployed.

## Prerequisites

- A DigitalOcean account
- An SSH key added to your DO account
- ~10 minutes

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

#### Step 1 — Server prep (as root)

Hardens the server, creates users, installs Node.js, and sets up Caddy for TLS:

```bash
curl -fsSL https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main/bootstrap.sh | bash -s
```

#### Step 2 — Install OpenClaw (as openclaw user)

```bash
sudo -u openclaw -i
curl -fsSL https://openclaw.ai/install.sh | bash
```

The installer runs onboarding automatically — you'll choose your messaging channel, enter your Telegram/Discord token, API key, etc.

> **Choosing your model.** Onboarding is also where you pick the **AI provider and model** — the model choice is entirely yours (Claude, OpenRouter, OpenAI, a local model, etc.); nothing here requires a particular one. To see what you ended up on, check `model.primary` in `~/.openclaw/openclaw.json` or the `[gateway] agent model: …` line in `openclaw gateway logs`. To change it later, edit `model.primary` in `~/.openclaw/openclaw.json` (and make sure the matching provider key is set), then restart the gateway.

#### Step 3 — Deploy team (still as openclaw user)

```bash
curl -fsSL https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main/install-team.sh \
  | bash -s -- --team operator
```

Done! Your team is deployed and ready to go.

## bootstrap.sh Options

```bash
curl -fsSL https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main/bootstrap.sh \
  | bash -s -- \
    --user szewong \
    --key "ssh-ed25519 AAAA..." \
    --domain example.com
```

| Flag | Description | Default |
|------|-------------|---------|
| `--user <name>` | Admin SSH username | `zuser-XXXX` (random 4-digit) |
| `--key "<pubkey>"` | SSH public key override | Copies from root's `authorized_keys` |
| `--domain <fqdn>` | Domain for Let's Encrypt TLS | Self-signed via IP |

## install-team.sh Options

Run as the `openclaw` user (after `sudo -u openclaw -i`):

```bash
curl -fsSL https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main/install-team.sh \
  | bash -s -- \
    --team operator \
    --api-key sk-ant-...
```

| Flag | Description | Default |
|------|-------------|---------|
| `--team <name>` | **Required.** Team to deploy | — |
| `--api-key <key>` | Anthropic API key (usually set during onboarding) | Leave `.env` as-is |

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

### Step 1: bootstrap.sh (3 phases)

1. **Server Hardening** — installs packages, creates an admin user with SSH key, configures UFW (ports 22/80/443), enables fail2ban, adds swap
2. **OpenClaw Prep** — creates an `openclaw` user with systemd lingering, installs Node.js 22.x
3. **Reverse Proxy** — installs Caddy, provisions TLS (Let's Encrypt with `--domain`, self-signed without), reverse proxies to the gateway

### Step 2: OpenClaw install (as openclaw user)

You switch to the `openclaw` user and install OpenClaw. The installer runs onboarding automatically — you'll choose your messaging channel, enter tokens, and set your API key.

### Step 3: Team deploy (as openclaw user)

Run `install-team.sh` which clones this repo, runs the team's `setup.sh`, and deploys agent workspaces and skills.

## After Deployment

### Edit your vision

```bash
sudo -u openclaw nano /home/openclaw/.openclaw/shared/VISION.md
```

### Service management

```bash
sudo -u openclaw -i openclaw gateway status
sudo -u openclaw -i openclaw gateway restart
sudo -u openclaw -i openclaw gateway logs
```

## Security

- **Admin user** (`zuser-XXXX` or custom): SSH access, sudo, system administration. Non-standard name deters brute-force bots.
- **`openclaw` user**: regular user with systemd lingering enabled, no SSH, no sudo — runs the gateway only.
- Root login is key-only (`PermitRootLogin prohibit-password`) for DO recovery.
- Password authentication is disabled.
- UFW allows only ports 22, 80, and 443.
- fail2ban protects SSH.

## Idempotency

All three steps are safe to run multiple times. Users are checked before creation, packages are idempotent, and team setup scripts handle existing installations.

## Troubleshooting

### Gateway isn't responding
```bash
sudo -u openclaw -i openclaw gateway status
sudo -u openclaw -i openclaw gateway logs
```

### Can't SSH as admin user
The admin username is printed at the end of bootstrap.sh. If you lost it, check:
```bash
# From root:
ls /home/
```

### OpenClaw binary not found after install
Make sure you installed as the `openclaw` user:
```bash
sudo -u openclaw -i
curl -fsSL https://openclaw.ai/install.sh | bash
```

### install-team.sh says "openclaw binary not found"
Run Step 2 first — install OpenClaw and complete onboarding as the `openclaw` user.

### Want more control?
Edit the team's files to adjust agent behavior:
- `/home/openclaw/.openclaw/shared/VISION.md` — business context
- `/home/openclaw/.openclaw/workspace-*/SOUL.md` — agent personality
- `/home/openclaw/.openclaw/shared/skills/*` — agent capabilities

## Questions?

See the full documentation: https://docs.openclaw.ai
