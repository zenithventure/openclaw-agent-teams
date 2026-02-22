# OpenClaw Agent Teams

A collection of [OpenClaw](https://openclaw.ai) multi-agent team configurations, each designed for a different class of work. Every team is self-contained with its own agents, skills, shared context, and setup script.

## Quick Start

Install any team on a machine already running [OpenClaw](https://docs.openclaw.ai):

```bash
git clone https://github.com/zenithventure/openclaw-agent-teams.git /tmp/openclaw-teams \
  && bash /tmp/openclaw-teams/operator/setup.sh
```

Then:

1. Edit `~/.openclaw/shared/VISION.md` with your mission and constraints
2. Update `USER.md` in each agent's workspace with your information
3. Set your API key in `~/.openclaw/.env`
4. Run `openclaw start`

## Deploy to DigitalOcean

One `curl` command takes a bare Ubuntu 24.04 droplet from **zero to a fully hardened, TLS-terminated, production-ready OpenClaw instance** — with your agent team already deployed and running as a systemd service. No manual setup, no config files to edit, no second SSH session.

Here's what that single command does across 5 automated phases:

1. **Hardens the server** — creates a randomized admin user, locks down SSH (key-only, no passwords), enables UFW (ports 22/80/443 only), activates fail2ban, and adds swap for low-memory droplets
2. **Installs OpenClaw** — sets up a dedicated `openclaw` system user (no login, no sudo), installs Node.js 22.x, installs OpenClaw, and registers it as a systemd service
3. **Deploys your team** — clones this repo, runs the team's `setup.sh`, wires up your API key, and sets correct file ownership
4. **Configures TLS** — installs Caddy as a reverse proxy with automatic Let's Encrypt certificates (or self-signed if no domain), so your gateway is HTTPS from minute one
5. **Starts everything** — launches the gateway, runs a health check, and prints your access URL, SSH command, and admin credentials

```bash
ssh root@YOUR_DROPLET_IP
```

Then run:

```bash
curl -fsSL https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main/bootstrap.sh \
  | bash -s -- --team operator
```

The script is idempotent — safe to run again if interrupted. See [DO-SETUP.md](DO-SETUP.md) for full options (`--domain`, `--api-key`, `--user`, etc.) and details.

## Teams

| Folder | Team | Agents | Purpose |
|--------|------|--------|---------|
| [`accountant/`](accountant/) | [Accountant](accountant/README.md) | Controller, Bookkeeper, Reporter, Tax Prep | AI-powered back-office accounting — categorize, reconcile, report, and track taxes |
| [`modernizer/`](modernizer/) | [Legacy Modernizer](modernizer/README.md) | Commander, Architect, Documenter, ComplianceGate, Migrator¹ | Modernize legacy applications through a phased, compliance-aware pipeline (LEARN → PLAN → EXECUTE) |
| [`operator/`](operator/) | [Operator](operator/README.md) | Commander, Spark, Anchor, Lens | Design, build, and operate an autonomous business that generates recurring revenue |
| [`product-builder/`](product-builder/) | [Product Builder](product-builder/README.md) | Architect, Builder, Ops, QA | Build products from idea to production using spec-first development and CI/CD |
| [`real-estate/`](real-estate/) | [Real Estate](real-estate/README.md) | Deal Maker, Analyst, Coordinator, Underwriter | AI deal desk — comps, financial review, due diligence, and pipeline management |
| [`recruiter/`](recruiter/) | [Recruiter](recruiter/README.md) | Headhunter, Interviewer, Coordinator, Compliance | AI-powered recruiting — source, screen, interview, and hire with built-in bias detection |

¹ **Modernizer agent mapping:** The modernizer has 5 logical agents but 4 agent directories (`red-commander`, `blue-lens`, `yellow-spark`, `green-anchor`). The 5th agent (Migrator) reuses `red-commander`'s directory, as Commander transitions into the Migrator role during the EXECUTE phase. See the [modernizer README](modernizer/README.md) for details.

Most teams ship example VISIONs in their `examples/` folder — copy one to `~/.openclaw/shared/VISION.md` as a starting point.

## Common Structure

Each team follows a shared layout:

```
team-name/
  openclaw.json          # Agent definitions, tool permissions, skill config
  setup.sh               # One-line installer for OpenClaw
  agents/                # Per-agent identity and context files
    agent-name/
      IDENTITY.md        # Name, type, role
      SOUL.md            # Personality, beliefs, communication style
      AGENTS.md          # How this agent works with teammates
      USER.md            # Human operator information
      HEARTBEAT.md       # Agent status tracking
  shared/                # Shared team context
    VISION.md            # Mission, success criteria, constraints, priorities
  skills/                # Team-specific skill definitions (if any)
```

## Setup Options

Every team's `setup.sh` supports the same interface. Replace `<team>` with any team name:

```bash
git clone https://github.com/zenithventure/openclaw-agent-teams.git /tmp/openclaw-teams \
  && bash /tmp/openclaw-teams/<team>/setup.sh
```

Available teams: `accountant`, `modernizer`, `operator`, `product-builder`, `real-estate`, `recruiter`

### Flags

```bash
./setup.sh --vision "Build a SaaS for ..."   # Set vision inline
./setup.sh --clean                             # Wipe and reinstall
./setup.sh --uninstall                         # Remove everything
```

## Customization

After installing a team, the main files to tailor are:

- **`~/.openclaw/shared/VISION.md`** — your mission, success criteria, constraints, and priorities. This is the most important file; every agent reads it.
- **`~/.openclaw/agents/*/USER.md`** — information about the human operator (you). Each agent has its own copy.
- **`~/.openclaw/agents/*/SOUL.md`** — personality and communication style. Tweak if you want a different tone.
- **`~/.openclaw/skills/`** — add or modify team skills to extend what agents can do.

## License

MIT
