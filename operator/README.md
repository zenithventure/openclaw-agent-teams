# Installation

## Quick Start (DigitalOcean)

The fastest way to get running:

1. **Deploy a DO OpenClaw droplet** from the [DigitalOcean Marketplace](https://marketplace.digitalocean.com/apps/openclaw)
2. **SSH into your droplet:**
   ```bash
   ssh root@YOUR_DROPLET_IP
   ```
3. **Download and run the team installer:**
   ```bash
   curl -sL https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main/operator/do-team-install.sh | bash -s -- operator
   ```
4. **Open your OpenClaw dashboard** at `https://your-droplet-ip`
5. **Edit `shared/VISION.md`** with your business context
6. **Start using your agents!**

**What the installer does:**
- Unlocks execution policies (enables agents to run tools)
- Injects team configuration into the sandbox
- Deploys all agents with DISC personalities
- Restarts OpenClaw to load everything

### Advanced (Bare Metal / Self-Hosted)

If you're running OpenClaw on your own infrastructure:

```bash
./setup.sh                    # Interactive setup
./setup.sh --clean            # Wipe and reinstall
./setup.sh --help             # Show help
```

See the [OpenClaw documentation](https://docs.openclaw.ai) for installation steps.

## Security Model

### How the Agents Run

**On DigitalOcean (Recommended):**
- Agents run under a dedicated `openclaw` user (not root)
- Execution happens inside a Docker container sandbox
- Network and filesystem access are restricted by default
- Execution policies must be explicitly unlocked

**Benefits:**
- Agents cannot escalate to root or modify system config
- Cannot access files outside their workspace
- Cannot bypass network restrictions
- Governance is enforced at the system level

**On Bare Metal:**
- Agents run with permissions you explicitly grant
- More control, but also more responsibility
- We recommend the same security principles: run as non-root, use process isolation

### Governance: What Gets Unlocked

When deployed on DO, three execution policies are unlocked:

**`tools.exec.host = gateway`** — Agents need a place to execute commands on a headless server

**`tools.exec.ask = off`** — No human approval needed (no one's there to approve anyway)

**`tools.exec.security = full`** — Full capability within the sandbox (network, filesystem operations)

The sandbox boundary (Docker container, non-root user) is where the actual security lives.

---


An [OpenClaw](https://openclaw.ai) agent team that designs, builds, and operates an **autonomous business** generating recurring revenue with minimal human intervention. The human acts as a board-level advisor, not a day-to-day manager.

## The Team

Four agents built on the [DISC personality model](https://en.wikipedia.org/wiki/DISC_assessment):

| Agent | Color | Role | Responsibility |
|-------|-------|------|----------------|
| **Commander** | Red | Team Lead & Execution Driver | Sets priorities, removes blockers, drives accountability, makes tough calls |
| **Spark** | Yellow | Creative Lead & Idea Generator | Ideation, opportunity discovery, creative problem-solving |
| **Anchor** | Green | Operations Lead & Team Glue | Day-to-day operations, team cohesion, process stability |
| **Lens** | Blue | Quality Lead & Analytical Engine | Data analysis, quality assurance, evidence-based decision-making |

## Skills

| Skill | Purpose |
|-------|---------|
| `vision-sync` | Team alignment with shared mission and priorities |
| `team-standup` | 30-minute team sync protocol |
| `daily-report` | 3x daily status reports to the human |

## Philosophy

Built on the **Freedom Startups** framework:

1. **Speed to revenue** over product perfection
2. **Automation depth** over feature breadth
3. **Unit economics viability** over growth rate
4. **Customer retention** over customer acquisition

The team operates 24x7 and escalates to the human only for spending over $50, legal/compliance questions, or strategic pivots.

## Getting Started

```bash
git clone https://github.com/zenithventure/openclaw-agent-teams.git
cd openclaw-agent-teams/operator
./setup.sh
```

1. Configure `shared/VISION.md` with your business mission and constraints
2. Update each agent's `USER.md` with your information
3. Let Commander take it from there

## Example Vision Ideas

- API-as-a-service, content generation tools, data enrichment
- Niche SaaS with low support burden and high margins
- Agent-powered services sold to customers
- Automated reporting or monitoring tools
