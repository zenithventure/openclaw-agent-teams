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

Three steps take a bare Ubuntu 24.04 droplet from **zero to a fully hardened, TLS-terminated, production-ready OpenClaw instance** with your agent team deployed.

```bash
ssh root@YOUR_DROPLET_IP
```

**Step 1 — Server prep (as root):**

```bash
curl -fsSL https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main/bootstrap.sh | bash -s
```

**Step 2 — Install OpenClaw (as openclaw user):**

```bash
sudo -u openclaw -i
curl -fsSL https://openclaw.ai/install.sh | bash
```

**Step 3 — Deploy team (still as openclaw user):**

```bash
curl -fsSL https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main/install-team.sh \
  | bash -s -- --team operator
```

All steps are idempotent — safe to run again if interrupted. See [DO-SETUP.md](DO-SETUP.md) for full options and details.

## Teams

| Folder | Team | Agents | Purpose |
|--------|------|--------|---------|
| [`accountant/`](accountant/) | [Accountant](accountant/README.md) | Controller, Bookkeeper, Reporter, Tax Prep | AI-powered back-office accounting — categorize, reconcile, report, and track taxes |
| [`dev/`](dev/) | [Dev (Claude Code)](dev/README.md) | Lead, Coder, Shipper, Reviewer | Autonomous engineering team that ships GitHub issues by spawning Claude Code subagents |
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
    STANDARDS.md         # Behavioral standards all agents follow (session boot, memory, safety, comms)
    BOOTSTRAP.md         # First-run setup wizard (configures USER.md + VISION.md, then self-deletes)
  skills/                # Team-specific skill definitions (if any)
```

## Setup Options

Every team's `setup.sh` supports the same interface. Replace `<team>` with any team name:

```bash
git clone https://github.com/zenithventure/openclaw-agent-teams.git /tmp/openclaw-teams \
  && bash /tmp/openclaw-teams/<team>/setup.sh
```

Available teams: `accountant`, `dev`, `modernizer`, `operator`, `product-builder`, `real-estate`, `recruiter`

### Flags

```bash
./setup.sh --vision "Build a SaaS for ..."   # Set vision inline
./setup.sh --clean                             # Wipe and reinstall
./setup.sh --uninstall                         # Remove everything
```

## Customization

After installing a team, the main files to tailor are:

- **`~/.openclaw/shared/VISION.md`** — your mission, success criteria, constraints, and priorities. This is the most important file; every agent reads it.
- **`~/.openclaw/shared/STANDARDS.md`** — behavioral standards every agent follows: session startup, memory management, safety rules, group chat etiquette, platform formatting, and heartbeat vs cron guidance. Edit to customize team-wide behavior.
- **`~/.openclaw/agents/*/USER.md`** — information about the human operator (you). Each agent has its own copy.
- **`~/.openclaw/agents/*/SOUL.md`** — personality and communication style. Tweak if you want a different tone.
- **`~/.openclaw/skills/`** — add or modify team skills to extend what agents can do.

## License

MIT
