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
   curl -sL https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main/product-builder/do-team-install.sh | bash -s -- product-builder
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


This OpenClaw setup represents a **modern developer team** built from the skills taught across the 6-week AI Product Builder program. It encodes the complete development workflow — from idea validation to production deployment — into a multi-agent system.

## The Team

| Agent | Color | Role | Responsibility |
|-------|-------|------|----------------|
| **Architect** | Red | Design Lead | System specs, architecture docs, issue sizing, validation |
| **Builder** | Yellow | Implementation | Full-stack coding via Claude Code, trunk-based workflow |
| **Ops** | Green | Operations | CI/CD pipeline, deployments, environment management, reporting |
| **QA** | Blue | Quality | Testing (Vitest + Playwright), PR review, production verification |

## Skills (from the 6-week curriculum)

| Skill | Week | What It Encodes |
|-------|------|-----------------|
| `spec-first-development` | Week 2 | System specs and architecture docs before code |
| `trunk-based-workflow` | Week 4 | Issue → Branch → Fix → PR → Merge → Delete lifecycle |
| `cicd-pipeline` | Week 5 | DEV/QA/PROD environments, automated build/test/deploy |
| `deploy-to-production` | Week 3 | Vercel deployment setup and auto-deploy workflow |
| `supabase-setup` | Week 2 | Backend configuration: DB, auth, Edge Functions, RLS |
| `stripe-integration` | Week 6 | Payment processing with subscriptions and webhooks |
| `mobile-development` | Week 6 | React Native / Expo companion app sharing same backend |
| `team-standup` | Week 6 | 30-minute team sync protocol |
| `daily-report` | Week 6 | 3x daily status reports to the human |
| `vision-sync` | Week 6 | Team alignment with shared mission and priorities |

## Tech Stack

- **Frontend:** Next.js (React, TypeScript)
- **Backend:** Supabase (PostgreSQL, Auth, Edge Functions, RLS)
- **Hosting:** Vercel (auto-deploy from GitHub, preview environments)
- **Payments:** Stripe (Checkout, Webhooks, Subscriptions)
- **Mobile:** React Native with Expo
- **Testing:** Vitest (unit), Playwright (E2E)
- **Version Control:** GitHub (Issues, Branches, PRs via `gh` CLI)
- **AI Tools:** Claude Code (primary development tool)

## Philosophy

This team is built on the **Freedom Startups** framework:

1. **Know yourself** — Find the intersection of what you love, what you're good at, and what creates value
2. **Find real pain** — Solve mundane, boring, sticky business problems
3. **Solve simply** — Build a coffee cart before a coffee shop
4. **Sell early** — 10 people paying $10 > 1000 free signups
5. **Spec first** — Think before you build, document before you code
6. **Trunk-based** — Ship small, merge fast, always be integrating
7. **Automate everything** — CI/CD pipelines, not manual deployments

## Getting Started

1. Configure `shared/VISION.md` with your project's mission
2. Update each agent's `USER.md` with your information
3. Have Architect create system specs for your idea
4. Let the team take it from there

---

*Built from the AI Product Builder 6-week program curriculum.*
