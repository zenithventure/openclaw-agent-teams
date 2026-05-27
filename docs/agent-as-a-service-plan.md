# Agent-as-a-Service — implementation plan

This is the working plan for turning this repo into an "agent-as-a-service"
setup: a user clones the repo, points **Claude Code** at it to author/iterate an
agent definition (1–N agents), and uses the deployer + **Ansible** to push and
update that bot across one or more host VMs.

**Status:** Phase 1 shipped (PR
[#38](https://github.com/zenithventure/openclaw-agent-teams/pull/38), branch
`claude/openclaw-agent-service-plan-8IYJw`). Phases 2–3 are open.

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

## Phase 2 — Ansible fleet inventory + update loop  ⬜ TODO

Goal: edit repo files → `ansible-playbook` → bots update on one or more VMs,
with per-host config (vision, API key, channel) layered over group defaults.

Steps:

1. **Add a committed inventory tree** under `ansible/inventory/`:
   ```
   ansible/inventory/
     production/
       hosts.yml                 # host groups
       group_vars/all.yml        # defaults: team, model, channel
       group_vars/<group>.yml    # per-group overrides
       host_vars/<host>.yml      # per-host: vision/vision_file, api key ref, channel token
     staging/ ...
   ```
   Ship example files (with placeholder hosts) so the structure is self-documenting.
2. **Rework `ansible/openclaw-team.yml`:**
   - Remove the hardcoded `valid_teams` assert (`ansible/openclaw-team.yml:23`);
     validate structurally that `{{ repo_root }}/{{ team }}/openclaw.json` and
     `agents/` exist.
   - Read `team`, `vision` / `vision_file`, `anthropic_api_key`, and channel
     tokens from group/host vars instead of only `-e team=`.
   - Deploy via `bash {{ repo_root }}/lib/deploy-team.sh --team-dir
     {{ repo_root }}/{{ team }}` (replaces the current `run the team's setup.sh`
     shell task, but keep working for modernizer — prefer team `setup.sh` if
     present, else the lib, mirroring `install-team.sh`).
   - Write `VISION.md` from `vision_file`/`vision`; set `.env` keys; reload the
     gateway (existing reload logic at `ansible/openclaw-team.yml:95` is fine).
   - Keep it idempotent so re-runs = updates. Declarative agent files refresh;
     `USER.md`/`VISION.md` seed-once unless explicitly overridden.
3. **Per-host config layering:** `host_vars/<host>.yml` provides `vision` (inline)
   or `vision_file` (committed, e.g. under the team's `examples/`), `team`,
   `channel` + token, and an API-key reference.
4. **Verify:** dry-run with `--check`; deploy to a throwaway host or container;
   confirm `-l <host>` targets a subset and a second run is a no-op diff.

## Phase 3 — secrets, docs, polish  ⬜ TODO

1. **Secrets guidance:** recommend **Ansible Vault** for committed secrets or
   `-e` / env injection; cross-link the **BWS pattern** already sketched in
   `docs/advanced.md`. Never commit plaintext keys in `host_vars`.
2. **Docs:**
   - README section **"Run your own agent as a service"** (clone → author with
     Claude → deploy → iterate).
   - Update `ansible/README.md` for the inventory model (replace the ad-hoc
     `-i hosts -e team=` examples).
3. **Optional:** a deploy-time structural sanity assert in the playbook (team has
   `openclaw.json` + `agents/`, every `agents/<id>` has an `openclaw.json` entry).

---

## Notes / risks

- **Reload caveat:** OpenClaw reads workspace files live; config changes need a
  gateway reload (the playbook does this). Confirm against the target OpenClaw
  version during Phase 2.
- **Don't reintroduce allowlists** — teams are discovered structurally in both
  `install-team.sh` and (after Phase 2) `openclaw-team.yml`.
- **Keep `modernizer/` bespoke** until/unless its structure is normalized.
