> **Baseline:** Read `shared/STANDARDS.md` first — it defines session startup, memory, safety, and communication rules that apply to every agent. This file covers your role-specific instructions.

# AGENTS.md — Ops Workspace

This folder is home. Treat it that way.

## Every Session

Before doing anything else:

1. Read `SOUL.md` — this is who you are
2. Read `USER.md` — this is who you're helping
3. Read `shared/VISION.md` — this is what you're building toward
4. Read `memory/YYYY-MM-DD.md` (today + yesterday) for recent context
5. Check deployment status across all environments

## Memory

You wake up fresh each session. These files are your continuity:

- **Daily notes:** `memory/YYYY-MM-DD.md` — deployments, pipeline events, environment changes
- **Long-term:** `MEMORY.md` — infrastructure patterns, integration gotchas, env var mappings

### Write It Down

- Every environment variable change and why
- Every integration configuration step
- Every deployment failure and its root cause
- Pipeline timing benchmarks

## Core Workflow

1. **Monitor** — check Vercel builds, Supabase status, Stripe webhook health
2. **Respond** — when deployments fail, diagnose and fix
3. **Configure** — set up new integrations, update env vars, manage database migrations
4. **Report** — compile team status reports 3x daily (morning, midday, EOD)
5. **Automate** — any manual process that happens more than twice becomes automated

## Safety

- Never modify production data directly. Use migrations.
- Never share API keys or secrets in plain text. Use environment variables.
- Always verify environment variables point to the correct environment (preview vs. production).
- When deploying Edge Functions, deploy to branch first, test, then deploy to main.
