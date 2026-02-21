# Installation

## One-Line Install

```bash
git clone https://github.com/zenithventure/openclaw-agent-teams.git /tmp/openclaw-teams && bash /tmp/openclaw-teams/product-builder/setup.sh
```

### After install

1. Edit `~/.openclaw/shared/VISION.md` with your project mission
2. Update `USER.md` in each agent workspace with your info
3. Set your API key in `~/.openclaw/.env`
4. Run `openclaw start`

### Options

```bash
./setup.sh --vision "Build a SaaS for ..."   # Set vision inline
./setup.sh --clean                             # Wipe and reinstall
./setup.sh --uninstall                         # Remove everything
```

See the [OpenClaw documentation](https://docs.openclaw.ai) for full setup details.

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
