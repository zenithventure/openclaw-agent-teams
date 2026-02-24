# Building a New OpenClaw Team

This directory is a developer reference for creating new agent teams. It contains canonical templates for every file an agent needs, along with the shared files that bind a team together.

Use this as your starting point. Copy the structure, fill in the blanks, and you have a deployable team.

---

## File Structure

Every team follows this layout:

```
team-name/
  README.md                  # Team overview (for humans browsing the repo)
  openclaw.json              # Agent definitions, tool permissions, skill config
  setup.sh                   # One-line installer for OpenClaw
  agents/
    red-<role>/              # Red agent (Dominance — Leader)
      AGENTS.md              # Role-specific workflow and instructions
      SOUL.md                # Personality, beliefs, communication style
      IDENTITY.md            # Name, type, color, DISC profile
      USER.md                # Human operator information (same across all agents)
      HEARTBEAT.md           # Check-in rhythm and schedule
    yellow-<role>/           # Yellow agent (Influence — Creative)
      ...same files...
    green-<role>/            # Green agent (Steadiness — Operations)
      ...same files...
    blue-<role>/             # Blue agent (Conscientiousness — Quality)
      ...same files...
  shared/
    VISION.md                # Mission, success criteria, constraints, priorities
    STANDARDS.md             # Baseline behavioral rules (canonical — do not edit per team)
    BOOTSTRAP.md             # First-run setup wizard (canonical — do not edit per team)
    standup-log.md           # Agent-maintained standup entries
  skills/                    # Team-specific skill definitions (optional)
    skill-name/
      SKILL.md
  examples/                  # Example VISION.md files for different use cases (optional)
```

---

## The DISC Structure

Every team uses four agents mapped to the DISC behavioral model. This gives each team a balanced mix of leadership, creativity, reliability, and rigor.

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

### STANDARDS.md (canonical)

Located in `shared/STANDARDS.md`. This file is identical across all teams — do not modify it per team. It defines:

- Session startup sequence (read SOUL, USER, VISION, memory)
- Memory management (daily notes, MEMORY.md, memory security)
- Safety rules (use trash, no exfiltration, ask before external actions)
- Group chat behavior (when to speak, when to stay silent)
- Platform formatting (Discord, WhatsApp, Telegram)
- Heartbeat vs cron distinction

Copy it from `_template/shared/STANDARDS.md`.

### BOOTSTRAP.md (canonical)

Located in `shared/BOOTSTRAP.md`. Also identical across all teams. It runs once on first boot to configure USER.md and VISION.md, then self-deletes. Copy it from `_template/shared/BOOTSTRAP.md`.

### VISION.md (team-specific)

Located in `shared/VISION.md`. This is the most important file for each team. It defines what the team is trying to accomplish. Use the template in `_template/shared/VISION.md` as a starting point — it has all the required sections with placeholder text.

### standup-log.md

Located in `shared/standup-log.md`. Starts empty. Agents write their standup entries here in reverse chronological order.

---

## setup.sh Structure

Every team needs a `setup.sh` that deploys the team to `~/.openclaw/`. The standard structure is:

1. **Banner** — team name and agent summary
2. **Preflight checks** — verify openclaw, node, gh are available
3. **Argument parsing** — support `--clean`, `--uninstall`, `--vision "text"`, `--help`
4. **Directory creation** — `~/.openclaw/workspace-<agent>/memory/`, `shared/reports/`, `skills/`
5. **Config deployment** — merge or copy `openclaw.json`
6. **Agent file deployment** — copy SOUL, IDENTITY, AGENTS, HEARTBEAT, USER into each workspace; symlink `shared/`
7. **Shared file deployment** — copy VISION, standup-log, STANDARDS, BOOTSTRAP
8. **Skill deployment** — copy SKILL.md files into `~/.openclaw/skills/`
9. **Env template** — create `.env` if it does not exist
10. **Summary** — print what was installed and next steps

Key behaviors:

- All operations are idempotent (safe to run again)
- Existing `openclaw.json` is merged, not replaced (when node is available)
- Agent workspaces get a symlink to `shared/` so agents can read `shared/VISION.md` directly
- The `.env` file is created with `chmod 600` and never overwritten

See any existing team's `setup.sh` (e.g., `operator/setup.sh`) as a working reference.

---

## Pre-Flight Checklist

Before deploying a new team, verify:

- [ ] **4 agents** — one Red, one Yellow, one Green, one Blue
- [ ] **Naming** — all directories use `color-role` format
- [ ] **AGENTS.md** — every agent has the `> **Baseline:**` line referencing STANDARDS.md
- [ ] **AGENTS.md** — every agent has Core Workflow and Safety sections
- [ ] **SOUL.md** — every agent has a distinct personality, beliefs, and team relationships
- [ ] **IDENTITY.md** — every agent has name, type, color, and DISC profile
- [ ] **USER.md** — identical across all four agents (placeholder or configured)
- [ ] **HEARTBEAT.md** — every agent has a check-in schedule relevant to their role
- [ ] **shared/VISION.md** — has all required sections (even if placeholder)
- [ ] **shared/STANDARDS.md** — copied from canonical template (not modified)
- [ ] **shared/BOOTSTRAP.md** — copied from canonical template (not modified)
- [ ] **shared/standup-log.md** — exists with header
- [ ] **openclaw.json** — all 4 agents defined with correct IDs and workspace paths
- [ ] **setup.sh** — tested on a clean machine, supports `--clean` and `--uninstall`
- [ ] **README.md** — team-level README explaining purpose, agents, and example VISIONs

---

## Template Files

This directory contains starter templates for every file listed above:

| File | Location | Purpose |
|------|----------|---------|
| AGENTS.md | `agents/example-agent/AGENTS.md` | Role-specific workflow template |
| SOUL.md | `agents/example-agent/SOUL.md` | Personality and beliefs template |
| IDENTITY.md | `agents/example-agent/IDENTITY.md` | Agent metadata template |
| USER.md | `agents/example-agent/USER.md` | Human operator info template |
| HEARTBEAT.md | `agents/example-agent/HEARTBEAT.md` | Check-in schedule template |
| VISION.md | `shared/VISION.md` | Team mission and goals template |
| STANDARDS.md | `shared/STANDARDS.md` | Canonical behavioral standards |
| BOOTSTRAP.md | `shared/BOOTSTRAP.md` | Canonical first-run setup |
| standup-log.md | `shared/standup-log.md` | Empty standup log starter |

Copy `agents/example-agent/` four times, rename to your color-role pairs, and fill in each file. Copy `shared/` into your team directory. You are ready to build.
