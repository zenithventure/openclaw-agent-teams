# Agent-as-a-Service — implementation plan

This is the working plan for turning this repo into an "agent-as-a-service"
setup: a user clones the repo, points **Claude Code** at it to author/iterate an
agent definition (1–N agents), and uses the deployer + **Ansible** to push and
update that bot across one or more host VMs.

**Status:** Phase 1 shipped (PR
[#38](https://github.com/zenithventure/openclaw-agent-teams/pull/38)). Phase 2
shipped (PR [#39](https://github.com/zenithventure/openclaw-agent-teams/pull/39)).
Phase 3 shipped on branch `claude/openclaw-phase3-secrets-docs`. **All phases
complete.**

> Other sessions: read [`../CLAUDE.md`](../CLAUDE.md) first (the authoring
> contract), then continue from the next unchecked phase below.

---

## Target workflow

1. **Clone** the repo onto a control machine (laptop or bastion).
2. **Author** — point Claude Code at the repo: *"create a support agent that
   triages tickets."* Claude writes/edits a team folder (`openclaw.json`,
   `agents/*`, `shared/*`, optional `skills/*`) following `CLAUDE.md`.
3. **Iterate** — *"now have it escalate refunds."* Claude edits the same files.
4. **Deploy / update** — `ansible-playbook -i inventory/<env> openclaw-team.yml
   -l <hosts>` pushes current repo state to the host VM(s) and reloads the
   gateway. Re-run anytime to roll out edits.

The "service" runtime already exists (the systemd user gateway from
`bootstrap.sh` / `ansible/bootstrap.yml`). The work is authoring legibility, a
generic deploy path, and a fleet inventory + update loop.

## Decisions (locked)

- **Agent shape:** custom team of **1–N agents** (not strictly 4-DISC). A single
  agent is valid.
- **Fleet model:** **group defaults + per-host overrides** (standard Ansible
  `group_vars` / `host_vars` layering).
- **Authoring UX:** **no scaffold/wizard tooling.** Claude Code edits repo data
  files directly; the repo is the source of truth. (A deploy-time sanity assert
  in the playbook is allowed — that's deploy robustness, not authoring tooling.)

---

## Phase 1 — core authoring + generic deploy  ✅ DONE

Shipped in PR #38. Summary:

- **`lib/deploy-team.sh`** — generic, data-driven deployer. Discovers agents from
  `agents/*/`, derives JSON-merge ids from `openclaw.json`, merges config
  (backup + idempotent), copies the whole `shared/` tree, installs skills (from
  `shared/skills/*` and `skills/*`), seeds `.env` (team `env.template` or
  generic). Flags: `--team-dir`, `--clean`, `--uninstall`, `--vision`, `--help`.
- **Built-in uniform teams → 17-line shims** over the deployer (operator, dev,
  recruiter, real-estate, accountant, product-builder). Verified byte-equivalent
  to the old scripts.
- **`modernizer/` keeps its bespoke `setup.sh`** — it breaks the naming
  convention (slashed ids, 5 logical agents / 4 dirs, no `workspace` keys). Do
  not migrate it to the generic lib.
- **`install-team.sh`** — dropped the hardcoded `VALID_TEAMS` allowlist; teams
  are discovered structurally (dir with `openclaw.json` + `agents/`). Prefers a
  team's own `setup.sh`, falls back to the generic deployer for pure-data teams.
- **`_template/`** is now a deployable single-agent team (added
  `_template/openclaw.json`); README + root **`CLAUDE.md`** reframed around 1–N
  agents and the edit→redeploy loop.
- Supporting: `dev/env.template`, `product-builder/env.template`,
  `accountant/shared/tax/.gitkeep`.

Validation done: all 8 teams deploy to temp dirs; idempotency, cross-team merge,
`--vision`, `--uninstall` verified; all scripts pass `bash -n`.

---

## Phase 2 — Ansible fleet inventory + update loop  ✅ DONE

Shipped on `claude/openclaw-ansible-fleet-phase2`. Summary:

- **`ansible/inventory/{production,staging}/`** committed example tree with
  `hosts.yml`, `group_vars/all.yml`, `host_vars/<host>.yml`. Self-documenting
  placeholders, plus `inventory/README.md` covering layering and secrets.
- **`ansible/openclaw-team.yml`** rewritten:
  - Dropped the `valid_teams` allowlist; pre_tasks now stat
    `{{ repo_root }}/{{ team }}/openclaw.json` and `agents/` on the controller
    and assert structurally.
  - Reads `team`, `vision` / `vision_file`, `anthropic_api_key`, and channel
    tokens (`telegram_bot_token`, `discord_bot_token`, `discord_user_id`,
    `slack_app_token`, `slack_bot_token`) from group/host vars.
  - **rsyncs the controller repo to the target** at
    `/home/openclaw/.openclaw-repo` (via `sudo rsync` + `--chown`), excluding
    `.git`, `.env`, backups, node_modules. This is what makes
    edit-repo→re-run-playbook work without a manual clone.
  - Deploys via the team's `setup.sh` when present (so `modernizer/` still
    works), else `lib/deploy-team.sh --team-dir …` — mirroring
    `install-team.sh`. `--vision` is passed inline when set.
  - `vision_file` (path relative to repo root on the controller) overwrites
    `~/.openclaw/shared/VISION.md` after deploy, taking precedence over
    `vision` for longer mission docs.
  - `.env` keys set via `lineinfile` with `no_log: true`.
  - Existing service patch + reload steps preserved.
- **`ansible/README.md`** rewritten around the inventory model — drops the
  hardcoded team list, shows `-i ansible/inventory/production`, links to
  `inventory/README.md`.

Validation done: YAML parses for all new/changed playbook + inventory files;
`lib/deploy-team.sh --team-dir _template` + `--vision …` smoke-tested in a
tempdir; bash array idiom `${EXTRA[@]+"${EXTRA[@]}"}` verified under
`set -euo pipefail`. Full `ansible-playbook --check` against a live target
is still owed (no Ansible in the sandbox where this was authored).

## Phase 3 — secrets, docs, polish  ✅ DONE

Shipped on `claude/openclaw-phase3-secrets-docs`. Summary:

1. **Secrets guidance:** `docs/advanced.md` now opens with a "choosing an
   approach" table comparing `-e` injection, Ansible Vault, and BWS (keys off
   disk), cross-linking the Vault / `-e` guidance in
   `ansible/inventory/README.md#secrets` (added in Phase 2) so the BWS doc is no
   longer an island. "Never commit plaintext keys" reinforced.
2. **Docs:**
   - Top-level `README.md` gained a **"Run your own agent as a service"**
     section (clone → author with Claude → deploy single-host/fleet → iterate),
     linking `CLAUDE.md` and this plan.
   - `ansible/README.md` was already reworked for the inventory model in Phase 2
     (no ad-hoc `-i hosts -e team=` examples remain).
3. **Structural sanity assert:** `openclaw-team.yml` pre_tasks now cross-check
   `agents/<id>/` dirs against `openclaw.json` ids (symmetric difference must be
   empty) on the controller before touching any host. Gated to *generic* teams
   via the `team_is_generic` fact (the same detection that gates vision), so
   `modernizer`'s deliberate convention break is exempt. The `team_supports_vision`
   fact from Phase 2 was generalized to `team_is_generic` and now drives both the
   vision and structural checks.

Validation done: YAML parses; the agents/id cross-check verified against all
built-in teams (7 generic teams MATCH, modernizer correctly skipped). Full
`ansible-playbook --check` against a live host still owed (no Ansible in the
authoring sandbox) — same caveat as Phase 2.

---

## Notes / risks

- **Reload caveat:** OpenClaw reads workspace files live; config changes need a
  gateway reload (the playbook does this). Confirm against the target OpenClaw
  version during Phase 2.
- **Don't reintroduce allowlists** — teams are discovered structurally in both
  `install-team.sh` and (after Phase 2) `openclaw-team.yml`.
- **Keep `modernizer/` bespoke** until/unless its structure is normalized.
