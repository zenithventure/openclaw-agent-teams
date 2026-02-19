# OpenClaw Agent Teams

A collection of [OpenClaw](https://openclaw.ai) multi-agent team configurations, each designed for a different class of work. Every team is self-contained with its own agents, skills, shared context, and setup script.

## Teams

| Folder | Team | Agents | Purpose |
|--------|------|--------|---------|
| [`modernizer/`](modernizer/) | Legacy Modernizer | Commander, Architect, Documenter, ComplianceGate, Migrator | Modernize legacy applications through a phased, compliance-aware pipeline (LEARN → PLAN → EXECUTE) |
| [`product-builder/`](product-builder/) | Product Builder | Architect, Builder, Ops, QA | Build products from idea to production using spec-first development, trunk-based workflows, and CI/CD |
| [`operator/`](operator/) | Operator | Commander, Spark, Anchor, Lens | Design, build, and operate an autonomous business that generates recurring revenue |

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

## Getting Started

1. Pick a team that fits your use case
2. Follow the team's own README for installation and configuration
3. Edit `shared/VISION.md` to set your mission and constraints
4. Update each agent's `USER.md` with your information
5. Run `setup.sh` to install into your OpenClaw environment

## License

MIT
