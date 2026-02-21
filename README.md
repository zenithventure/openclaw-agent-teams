# OpenClaw Agent Teams

A collection of [OpenClaw](https://openclaw.ai) multi-agent team configurations, each designed for a different class of work. Every team is self-contained with its own agents, skills, shared context, and setup script.

## Teams

| Folder | Team | Agents | Purpose |
|--------|------|--------|---------|
| [`modernizer/`](modernizer/) | Legacy Modernizer | Commander, Architect, Documenter, ComplianceGate, Migrator¹ | Modernize legacy applications through a phased, compliance-aware pipeline (LEARN → PLAN → EXECUTE) |
| [`product-builder/`](product-builder/) | Product Builder | Architect, Builder, Ops, QA | Build products from idea to production using spec-first development, trunk-based workflows, and CI/CD |
| [`operator/`](operator/) | Operator | Commander, Spark, Anchor, Lens | Design, build, and operate an autonomous business that generates recurring revenue |
| [`accountant/`](accountant/) | Accountant | Controller, Bookkeeper, Reporter, Tax Prep | AI-powered back-office accounting for small businesses — categorize, reconcile, report, and track taxes |
| [`recruiter/`](recruiter/) | Recruiter | Headhunter, Interviewer, Coordinator, Compliance | AI-powered recruiting team — source, screen, interview, and hire with built-in bias detection |
| [`real-estate/`](real-estate/) | Real Estate | Deal Maker, Analyst, Coordinator, Underwriter | AI deal desk for real estate — comps, financial review, due diligence, and pipeline management |

¹ **Modernizer agent mapping:** The modernizer has 5 logical agents but 4 agent directories (`red-commander`, `blue-lens`, `yellow-spark`, `green-anchor`). The 5th agent (Migrator) reuses `red-commander`'s directory, as Commander transitions into the Migrator role during the EXECUTE phase. See the [modernizer README](modernizer/) for details.

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

## One-Line Install

Pick a team and install it on any machine running [OpenClaw](https://docs.openclaw.ai):

```bash
# Product Builder
git clone https://github.com/zenithventure/openclaw-agent-teams.git /tmp/openclaw-teams && bash /tmp/openclaw-teams/product-builder/setup.sh

# Accountant
git clone https://github.com/zenithventure/openclaw-agent-teams.git /tmp/openclaw-teams && bash /tmp/openclaw-teams/accountant/setup.sh

# Recruiter
git clone https://github.com/zenithventure/openclaw-agent-teams.git /tmp/openclaw-teams && bash /tmp/openclaw-teams/recruiter/setup.sh

# Real Estate
git clone https://github.com/zenithventure/openclaw-agent-teams.git /tmp/openclaw-teams && bash /tmp/openclaw-teams/real-estate/setup.sh

# Modernizer
git clone https://github.com/zenithventure/openclaw-agent-teams.git /tmp/openclaw-teams && bash /tmp/openclaw-teams/modernizer/setup.sh

# Operator
git clone https://github.com/zenithventure/openclaw-agent-teams.git /tmp/openclaw-teams && bash /tmp/openclaw-teams/operator/setup.sh
```

### After install

1. Edit `~/.openclaw/shared/VISION.md` with your mission and constraints
2. Update `USER.md` in each agent's workspace with your information
3. Set your API key in `~/.openclaw/.env`
4. Run `openclaw start`

### Options

```bash
./setup.sh --vision "Build a SaaS for ..."   # Set vision inline
./setup.sh --clean                             # Wipe and reinstall
./setup.sh --uninstall                         # Remove everything
```

## License

MIT
