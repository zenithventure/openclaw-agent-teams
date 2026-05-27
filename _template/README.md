# Building a New OpenClaw Team

This directory is a developer reference for creating new agent teams, and is itself a **valid, deployable single-agent team** (it ships an `openclaw.json` and one `example-agent`). It contains canonical templates for every file an agent needs, along with the shared files that bind a team together.

Use this as your starting point. Copy `_template/` to `<your-team>/`, fill in the blanks, and you have a deployable team. A team is **pure data** — you do not need to write a deploy script (see [How deploy works](#how-deploy-works)). For the full authoring contract, see [`../CLAUDE.md`](../CLAUDE.md).

A team holds **1 to N agents**. A single agent is completely valid; the four-color DISC layout below is a common, balanced *pattern* for multi-agent teams — not a requirement.

---

## File Structure

```
team-name/
  README.md                  # Team overview (for humans browsing the repo) — optional
  openclaw.json              # OPTIONAL — synthesized from agents/ if absent; ship it to customize names/tools/perms
  setup.sh                   # OPTIONAL — thin shim over lib/deploy-team.sh (built-in teams have one)
  env.template               # OPTIONAL — custom .env with extra provider/service keys
  agents/                    # REQUIRED — one directory per agent (1..N)
    <agent-id>/              # e.g. red-commander, or just support-bot for a solo agent
      AGENTS.md              # Role-specific workflow and instructions
      SOUL.md                # Personality, beliefs, communication style
      IDENTITY.md            # Name, type, color, DISC profile
      USER.md                # Human operator information (same across all agents)
      HEARTBEAT.md           # Check-in rhythm and schedule
  shared/
    VISION.md                # Mission, success criteria, constraints, priorities
    # STANDARDS.md / BOOTSTRAP.md are NOT vendored — the deployer supplies the
    # canonical copies from _template/shared. Ship your own only to override.
    standup-log.md           # Agent-maintained standup entries
    skills/                  # Team-specific skill definitions (optional)
      skill-name/
        SKILL.md
  examples/                  # Example VISION.md files for different use cases (optional)
```

The deployer maps each `agents/<agent-id>/` to an `openclaw.json` agent with
`"id": "<agent-id>"` and `"workspace": "~/.openclaw/workspace-<agent-id>"`. Keep
the directory name, the `id`, and the workspace path in sync.

---

## The DISC Structure (a pattern for multi-agent teams)

The built-in multi-agent teams use four agents mapped to the DISC behavioral model. This gives a team a balanced mix of leadership, creativity, reliability, and rigor. It is a recommended pattern when you want a full team — not a hard requirement. Author one agent, or three, or six, as the job demands.

| Color  | DISC Profile       | Team Function      | Typical Role Names                     |
|--------|--------------------|--------------------|----------------------------------------|
| Red    | Dominance          | Leader / Driver    | commander, architect, controller, dealmaker |
| Yellow | Influence          | Creative / Ideas   | spark, builder, bookkeeper, interviewer    |
| Green  | Steadiness         | Operations / Glue  | anchor, ops, coordinator, reporter         |
| Blue   | Conscientiousness  | Quality / Analysis | lens, qa, compliance, underwriter          |

### Naming Convention

Agent directories use `color-role` format:

- `red-commander` (not `commander` or `red`)
- `yellow-spark` (not `spark` or `yellow-creative`)
- `green-anchor` (not `anchor` or `green-ops`)
- `blue-lens` (not `lens` or `blue-quality`)

The role name should be short (one word, two max) and describe what the agent *does*, not what it *is*. Prefer concrete nouns over abstract ones.

---

## Required AGENTS.md Structure

Every `AGENTS.md` must start with a baseline reference to `shared/STANDARDS.md`, then provide role-specific instructions. The required sections are:

```markdown
> **Baseline:** Read `shared/STANDARDS.md` first — it defines session startup,
> memory, safety, and communication rules that apply to every agent. This file
> covers your role-specific instructions.

# AGENTS.md — [Role Name]'s Workspace

This folder is home. Treat it that way.

## Core Workflow
[Step-by-step instructions for this agent's primary responsibilities]

## Safety
[Role-specific guardrails — what this agent must NOT do]
```

The `> **Baseline:**` line is critical. It tells the agent to load STANDARDS.md before anything else. Without it, the agent misses the shared behavioral rules (session startup, memory management, safety, group chat etiquette, platform formatting, heartbeat vs cron).

You may add additional sections (e.g., `## Every Session`, `## Memory`) if the role needs to override or extend the baseline behavior, but the three above are the minimum.

---

## Shared Files

### STANDARDS.md (canonical — do NOT vendor)

The single copy lives here in `_template/shared/STANDARDS.md`. **Your team should not ship its own** — the deployer (`lib/deploy-team.sh`) copies this canonical file into `~/.openclaw/shared/STANDARDS.md` for every team. It defines:

- Session startup sequence (read SOUL, USER, VISION, memory)
- Memory management (daily notes, MEMORY.md, memory security)
- Safety rules (use trash, no exfiltration, ask before external actions)
- Group chat behavior (when to speak, when to stay silent)
- Platform formatting (Discord, WhatsApp, Telegram)
- Heartbeat vs cron distinction

Ship a `shared/STANDARDS.md` in your team only to deliberately override it — and the validator requires it stay byte-identical to this one, so there's rarely a reason to.

### BOOTSTRAP.md (canonical — do NOT vendor)

Same story: the canonical copy is `_template/shared/BOOTSTRAP.md`, supplied to every team by the deployer (seed-once — the agent self-deletes it on first run). It runs once on first boot to configure USER.md and VISION.md. Don't vendor your own.

### VISION.md (team-specific)

Located in `shared/VISION.md`. This is the most important file for each team. It defines what the team is trying to accomplish. Use the template in `_template/shared/VISION.md` as a starting point — it has all the required sections with placeholder text.

### standup-log.md

Located in `shared/standup-log.md`. Starts empty. Agents write their standup entries here in reverse chronological order.

---

<a name="how-deploy-works"></a>
## How deploy works

You do **not** write a deploy script. The generic deployer at
[`../lib/deploy-team.sh`](../lib/deploy-team.sh) deploys any team directory to
`~/.openclaw/`, driven entirely by the team's data:

```bash
bash lib/deploy-team.sh --team-dir <your-team>             # install / update
bash lib/deploy-team.sh --team-dir <your-team> --vision "Mission text"
bash lib/deploy-team.sh --team-dir <your-team> --clean     # wipe + reinstall
bash lib/deploy-team.sh --team-dir <your-team> --uninstall # remove
```

It discovers your agents (from `agents/*/`), merges your `openclaw.json` into any
existing config, copies agent workspaces and the `shared/` tree, installs skills,
and seeds `.env`. Key behaviors:

- **Idempotent** — safe to re-run; re-running is how you push an update.
- **Merged, not replaced** — existing `openclaw.json` is backed up then merged
  (your agents added/refreshed, others left alone), so teams coexist on one host.
- **Declarative refresh** — `SOUL/IDENTITY/AGENTS/HEARTBEAT` always refresh;
  `USER.md` and `VISION.md` are seeded once so live edits survive re-deploys
  (use `--vision` to overwrite the mission deliberately).
- **`.env`** — created `chmod 600`, never overwritten; ships from a team
  `env.template` if present, else a generic template.

A built-in team's `setup.sh` is just a thin shim that calls this deployer, so
`./<team>/setup.sh` still works. New teams need no `setup.sh`. (`modernizer/` is
the one exception that keeps bespoke logic.)

---

## Pre-Flight Checklist

Before deploying a new team, verify:

- [ ] **1+ agents** — a single agent is fine; use the DISC pattern for full teams
- [ ] **Naming** — `agents/<id>/` dir name matches its `openclaw.json` `id` and
      `workspace-<id>` (use `color-role` for multi-agent teams)
- [ ] **AGENTS.md** — every agent has the `> **Baseline:**` line referencing STANDARDS.md
- [ ] **AGENTS.md** — every agent has Core Workflow and Safety sections
- [ ] **SOUL.md** — every agent has a distinct personality, beliefs, and relationships
- [ ] **IDENTITY.md** — every agent has name, type, and (for DISC teams) color/profile
- [ ] **USER.md** — present for each agent (placeholder or configured)
- [ ] **HEARTBEAT.md** — every agent has a check-in schedule relevant to their role
- [ ] **shared/VISION.md** — has all required sections (even if placeholder)
- [ ] **shared/STANDARDS.md / BOOTSTRAP.md** — NOT vendored (the deployer supplies them from `_template`)
- [ ] **shared/standup-log.md** — exists with header
- [ ] **openclaw.json** — OPTIONAL (synthesized from `agents/` if absent); if shipped, every agent has a matching `id` + workspace path
- [ ] **Validates** — `bash lib/validate-team.sh --team-dir <your-team> --deploy`
- [ ] **README.md** — team-level README explaining purpose, agents, and example VISIONs

---

## Template Files

This directory contains starter templates for every file listed above:

| File | Location | Purpose |
|------|----------|---------|
| openclaw.json | `openclaw.json` | Single-agent config — extend `agents.list` for more |
| AGENTS.md | `agents/example-agent/AGENTS.md` | Role-specific workflow template |
| SOUL.md | `agents/example-agent/SOUL.md` | Personality and beliefs template |
| IDENTITY.md | `agents/example-agent/IDENTITY.md` | Agent metadata template |
| USER.md | `agents/example-agent/USER.md` | Human operator info template |
| HEARTBEAT.md | `agents/example-agent/HEARTBEAT.md` | Check-in schedule template |
| VISION.md | `shared/VISION.md` | Team mission and goals template |
| STANDARDS.md | `shared/STANDARDS.md` | Canonical behavioral standards — **the deployer's source; don't copy into your team** |
| BOOTSTRAP.md | `shared/BOOTSTRAP.md` | Canonical first-run setup — **the deployer's source; don't copy into your team** |
| standup-log.md | `shared/standup-log.md` | Empty standup log starter |

For a **solo agent**, fill in `agents/example-agent/` and the single entry in
`openclaw.json`. For a **full team**, copy `agents/example-agent/` once per agent
(rename to your `color-role` pairs) and add a matching entry to `openclaw.json`
for each. Copy `shared/VISION.md` and `shared/standup-log.md` either way — but
**not** `STANDARDS.md`/`BOOTSTRAP.md` (the deployer supplies those). You are ready to build.
