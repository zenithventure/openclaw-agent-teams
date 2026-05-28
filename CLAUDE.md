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

A team is a top-level directory containing an `agents/` folder (and usually an
`openclaw.json`). It holds **1 to N agents**. A single-agent team is completely
valid — the four-color DISC model used by the built-in teams is a useful
*pattern*, not a requirement. Author as many agents as the job needs.

For a **uniform team** — one whose config is fully implied by its `agents/` dirs
— you can omit `openclaw.json` entirely: the deployer synthesizes a default
(each `agents/<id>/` → an agent with id `<id>`, a Title-Cased name, workspace
`~/.openclaw/workspace-<id>`, subagents `["*"]`, agent-to-agent enabled for all
ids). Ship an explicit `openclaw.json` only to customize names, tools, or
permissions.

```
<team-name>/
  openclaw.json            # OPTIONAL — synthesized from agents/ if absent; ship to customize
  agents/                  # REQUIRED — one directory per agent
    <agent-id>/
      IDENTITY.md          # name, type, role (quick-reference card)
      SOUL.md              # personality, beliefs, communication style
      AGENTS.md            # role-specific workflow + safety (see baseline rule below)
      HEARTBEAT.md         # check-in rhythm
      USER.md              # human-operator info (seed-once; survives re-deploys)
  shared/                  # team-wide context (copied verbatim into ~/.openclaw/shared)
    VISION.md              # mission, success criteria, constraints, priorities (MOST IMPORTANT)
    standup-log.md         # starts with a header; agents append entries
    skills/<name>/SKILL.md # OPTIONAL — team skills, installed into ~/.openclaw/skills
    # STANDARDS.md and BOOTSTRAP.md are NOT vendored per team — the deployer
    # supplies them from _template/shared (single source of truth). Ship your
    # own copy only to override, and keep it byte-identical or the validator fails.
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

You only need this file to **customize** beyond the synthesized default (custom
agent names, tool permissions, agent-to-agent allowlists, skills dirs). A
uniform team can omit it. When you do ship one, this is the minimum viable
config (single agent):

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

> **Deploying to a real droplet?** Read
> [`docs/deployment-notes.md`](docs/deployment-notes.md) first. It records the
> actual fresh-droplet sequence — including the easy-to-miss **`openclaw` gateway
> install** step that no playbook runs — plus the Ansible core 2.19 gotchas and the
> `-e key="value with spaces"` truncation trap. For API keys resolved from Bitwarden
> at gateway start (nothing written to `~/.openclaw/.env`), follow
> [`docs/secrets-bws.md`](docs/secrets-bws.md).

---

## Authoring checklist

Run the validator — it mechanizes everything below and CI runs it on every PR:

```bash
bash lib/validate-team.sh --team-dir <team-name>   # one team
bash lib/validate-team.sh --all --deploy            # every team + deploy smoke test
```

Errors fail the build (invalid JSON, `agents/<id>` ⇄ `openclaw.json` id mismatch,
missing required files, missing `> **Baseline:**` line, canonical files edited,
`setup.sh` syntax). Warnings (e.g. a missing `## Core Workflow`/`## Safety`
heading) are advisory. The manual checklist, for reference:

- [ ] `agents/` exists with 1+ agent dirs. `openclaw.json` is optional; if you
      ship one, every `agents/<id>/` must have a matching `id` + `workspace`.
- [ ] 1+ agents; each has IDENTITY, SOUL, AGENTS, HEARTBEAT, USER.
- [ ] Every `AGENTS.md` starts with the `> **Baseline:**` line and has Core
      Workflow + Safety.
- [ ] `shared/VISION.md` filled in (mission, success criteria, constraints,
      priorities) — this is what every agent reads to judge its work.
- [ ] Do **not** vendor `shared/STANDARDS.md` or `shared/BOOTSTRAP.md` — the
      deployer supplies them from `_template/`. (Ship an override only if you
      must, and keep it byte-identical.)
- [ ] `shared/standup-log.md` present.
- [ ] Skills (if any) under `shared/skills/<name>/SKILL.md`.
- [ ] Deploys cleanly to a temp dir:
      `OPENCLAW_DIR=$(mktemp -d) bash lib/deploy-team.sh --team-dir <team-name>`.

---

## Don't

- Don't hard-code a team allowlist anywhere — teams are discovered structurally.
- Don't vendor or edit `shared/STANDARDS.md` / `shared/BOOTSTRAP.md` per team —
  they're canonical and supplied from `_template/shared` by the deployer.
- Don't write a per-team deploy script unless the team genuinely needs bespoke
  logic (modernizer is the only current example).
- Don't put real API keys in `env.template` or committed `host_vars` — keys are
  injected at deploy time (see `docs/advanced.md` and `ansible/`).
