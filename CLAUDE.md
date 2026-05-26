# CLAUDE.md — Authoring agents in this repo

This repo runs **OpenClaw agent teams as a service**. You (Claude Code) are the
authoring interface: a user points you at this repo and says *"build me an agent
that does X"* or *"change how the support bot behaves."* You edit **data files**
in a team directory; a deployer (`lib/deploy-team.sh`) and Ansible push that data
to one or more host VMs running the OpenClaw gateway. Re-running the deployer
updates a live bot.

**Your job when authoring:** create or edit a team directory so it is valid,
internally consistent, and deployable. A team is *pure data* — you almost never
need to write a shell script.

> **In-progress work:** the "agent-as-a-service" build-out has a checked-in plan
> at [`docs/agent-as-a-service-plan.md`](docs/agent-as-a-service-plan.md).
> Phase 1 (this generic deployer + authoring contract) is shipped; Phases 2–3
> (Ansible fleet inventory, secrets, docs) are open. If you're continuing that
> work, start from the next unchecked phase there.

---

## What a team is

A team is a top-level directory containing an `openclaw.json` and an `agents/`
folder. It holds **1 to N agents**. A single-agent team is completely valid — the
four-color DISC model used by the built-in teams is a useful *pattern*, not a
requirement. Author as many agents as the job needs.

```
<team-name>/
  openclaw.json            # REQUIRED — agent definitions, tool perms, skills config
  agents/                  # REQUIRED — one directory per agent
    <agent-id>/
      IDENTITY.md          # name, type, role (quick-reference card)
      SOUL.md              # personality, beliefs, communication style
      AGENTS.md            # role-specific workflow + safety (see baseline rule below)
      HEARTBEAT.md         # check-in rhythm
      USER.md              # human-operator info (seed-once; survives re-deploys)
  shared/                  # team-wide context (copied verbatim into ~/.openclaw/shared)
    VISION.md              # mission, success criteria, constraints, priorities (MOST IMPORTANT)
    STANDARDS.md           # canonical behavioral baseline — copy from _template, do not edit
    BOOTSTRAP.md           # canonical first-run wizard — copy from _template, do not edit
    standup-log.md         # starts with a header; agents append entries
    skills/<name>/SKILL.md # OPTIONAL — team skills, installed into ~/.openclaw/skills
  env.template             # OPTIONAL — custom .env with extra provider/service keys
  README.md                # OPTIONAL but recommended — human-facing team overview
```

`_template/` is the canonical starting point. To create a new team, copy
`_template/` to `<team-name>/`, then fill in the files. `_template/` is itself a
valid, deployable single-agent team — use it as a working reference.

---

## The naming convention (important)

The deployer maps **`agents/<agent-id>/` → openclaw.json agent `id: "<agent-id>"`
→ workspace `~/.openclaw/workspace-<agent-id>`**. Keep these three in sync:

- Directory `agents/blue-lens/` ⇒ `openclaw.json` entry with `"id": "blue-lens"`
  and `"workspace": "~/.openclaw/workspace-blue-lens"`.
- Every `id` in `openclaw.json` should have a matching `agents/<id>/` directory.
- JSON-level merge (add/remove/agent-to-agent) is keyed on the `openclaw.json`
  ids, so they are the source of truth — but matching the dir name keeps things
  legible. Use the `color-role` style (`red-commander`, `yellow-spark`) for
  multi-agent teams; a single agent can use any short slug (`support-bot`).

`modernizer/` deliberately breaks this convention (slashed ids, 5 logical agents
across 4 dirs) and therefore keeps a **bespoke `setup.sh`**. Do not copy
modernizer as a template; copy `_template/` or one of the four-color teams.

---

## openclaw.json conventions

Minimum viable config (single agent):

```json
{
  "agents": {
    "defaults": { "compaction": { "mode": "safeguard" }, "maxConcurrent": 4,
                  "subagents": { "maxConcurrent": 8 } },
    "list": [
      { "id": "support-bot", "name": "Support",
        "workspace": "~/.openclaw/workspace-support-bot",
        "subagents": { "allowAgents": ["*"] } }
    ]
  },
  "tools": { "agentToAgent": { "enabled": true, "allow": ["support-bot"] } },
  "skills": { "load": { "extraDirs": ["~/.openclaw/skills"] } }
}
```

The deployer **merges** this into any existing `~/.openclaw/openclaw.json`
(it backs up first). On merge it:
- adds your agents to `agents.list` (replacing any with the same id — idempotent),
- adds your agent ids to `tools.agentToAgent.allow`,
- adds your `skills.load.extraDirs` entries.

So multiple teams can coexist on one host. Put every agent id in
`agentToAgent.allow` if you want them to message each other.

---

## AGENTS.md baseline rule

Every agent's `AGENTS.md` MUST begin with the baseline reference so the agent
loads the shared standards before anything else:

```markdown
> **Baseline:** Read `shared/STANDARDS.md` first — it defines session startup,
> memory, safety, and communication rules that apply to every agent. This file
> covers your role-specific instructions.
```

Then provide at least `## Core Workflow` and `## Safety` sections.

---

## How deploy / update works

You do **not** write a deploy script. The generic deployer handles any team:

```bash
bash lib/deploy-team.sh --team-dir <team-name>      # install or update
bash lib/deploy-team.sh --team-dir <team-name> --vision "Mission text"
bash lib/deploy-team.sh --team-dir <team-name> --clean       # wipe + reinstall
bash lib/deploy-team.sh --team-dir <team-name> --uninstall   # remove
```

Built-in teams also have a thin `setup.sh` shim (`./<team>/setup.sh`) that just
calls the deployer, so older docs/commands keep working. A new team you author
does **not** need a `setup.sh` — pure data is enough. Remote deploy uses
`install-team.sh --team <team-name>` (single host) or the Ansible playbooks in
`ansible/` (fleets); both discover any team directory structurally, so authored
teams deploy with no allowlist changes.

**Iteration loop:** edit the team's files → re-run the deployer (or the Ansible
playbook) → the gateway reload picks up new agent files, skills, and config.
Declarative files (`SOUL/IDENTITY/AGENTS/HEARTBEAT`) always refresh; `USER.md`
and `VISION.md` are seeded once so live customizations survive re-deploys (use
`--vision` to overwrite the mission deliberately).

---

## Authoring checklist

Before considering a team done:

- [ ] `openclaw.json` exists; every `agents/<id>/` has a matching `id` + `workspace`.
- [ ] 1+ agents; each has IDENTITY, SOUL, AGENTS, HEARTBEAT, USER.
- [ ] Every `AGENTS.md` starts with the `> **Baseline:**` line and has Core
      Workflow + Safety.
- [ ] `shared/VISION.md` filled in (mission, success criteria, constraints,
      priorities) — this is what every agent reads to judge its work.
- [ ] `shared/STANDARDS.md` and `shared/BOOTSTRAP.md` copied unmodified from
      `_template/`.
- [ ] `shared/standup-log.md` present.
- [ ] Skills (if any) under `shared/skills/<name>/SKILL.md`.
- [ ] Deploys cleanly to a temp dir:
      `OPENCLAW_DIR=$(mktemp -d) bash lib/deploy-team.sh --team-dir <team-name>`.

---

## Don't

- Don't hard-code a team allowlist anywhere — teams are discovered structurally.
- Don't edit `shared/STANDARDS.md` or `shared/BOOTSTRAP.md` per team (canonical).
- Don't write a per-team deploy script unless the team genuinely needs bespoke
  logic (modernizer is the only current example).
- Don't put real API keys in `env.template` or committed `host_vars` — keys are
  injected at deploy time (see `docs/advanced.md` and `ansible/`).
