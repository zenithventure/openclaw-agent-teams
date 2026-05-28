# Ansible (optional)

The shell scripts at the repo root (`bootstrap.sh`, `install-team.sh`, and
the team `setup.sh`s) are the primary deployment path. The two playbooks
here mirror the same flow declaratively for fleets of hosts.

If you're deploying a single droplet, **use the shell flow** — open
[DO-SETUP.md](../DO-SETUP.md). If you're deploying many hosts, or you
want declarative inventory + per-host overrides, use these playbooks.

---

## Requirements

- **Ansible** — tested on ansible-core 2.20. Install the required collections
  with `ansible-galaxy collection install -r ansible/requirements.yml`
  (`ansible.posix` for `synchronize`, `community.general` for `ufw`).
- **GNU `rsync` on the control machine** — `openclaw-team.yml`'s `synchronize`
  task passes `--chown`, which macOS's default **openrsync** rejects
  (`rsync: unrecognized option '--chown'`). On macOS: `brew install rsync`, then
  make sure it precedes `/usr/bin/rsync` on `PATH` — e.g. run with
  `PATH="$(brew --prefix)/bin:$PATH" ansible-playbook …`. Targets need `rsync`
  too (Ubuntu ships it).
- Targets running Ubuntu 24.04 with SSH access as a sudo-capable user

---

## Playbooks

### `bootstrap.yml`

Equivalent to `bootstrap.sh` — hardens the server, creates the `openclaw`
and `claude` users, installs Node.js 22, and provisions Caddy with TLS.

Run as root (or via `become: true`):

```bash
ansible-playbook -i ansible/inventory/production ansible/bootstrap.yml \
  -e admin_user=szewong \
  -e domain=teams.example.com
```

Variables:
- `admin_user` — admin SSH username (default: random `zuser-XXXX`)
- `ssh_key` — admin SSH public key (default: copy from root's authorized_keys)
- `domain` — Let's Encrypt domain; omit for self-signed TLS

### `openclaw-team.yml`

Inventory-driven team deploy. Reads `team`, `vision` / `vision_file`, and
provider/channel secrets from your inventory (group_vars + host_vars),
rsyncs the current repo to each target, and runs the generic deployer
(`lib/deploy-team.sh`). Any team directory in the repo with
`openclaw.json` + `agents/` is deployable — no allowlist.

```bash
# Whole production fleet
ansible-playbook -i ansible/inventory/production ansible/openclaw-team.yml

# One host
ansible-playbook -i ansible/inventory/production ansible/openclaw-team.yml \
  -l example-host-1.example.com

# Inline overrides for a one-off run
ansible-playbook -i ansible/inventory/production ansible/openclaw-team.yml \
  -e team=operator -e anthropic_api_key=sk-ant-...
```

Variables (set in `host_vars/<host>.yml`, `group_vars/all.yml`, or `-e`):

| Variable | Required | Notes |
|----------|----------|-------|
| `team` | yes | Top-level directory in the repo with `openclaw.json` + `agents/` |
| `vision` | no | Inline mission statement (generic/data teams only — see note) |
| `vision_file` | no | Path (relative to repo root) to a markdown mission file — wins over `vision` (generic/data teams only) |
| `anthropic_api_key` | no\* | Sets `ANTHROPIC_API_KEY` in `~/.openclaw/.env`. \*Required for the gateway to work |
| `telegram_bot_token`, `discord_bot_token`, `discord_user_id`, `slack_app_token`, `slack_bot_token` | no | Channel bindings — only set what each host uses |

> **`vision`/`vision_file` apply to generic (data) teams only.** A team with a
> bespoke `setup.sh` that does not forward to `lib/deploy-team.sh` (currently
> only `modernizer`) keeps its mission in a team-specific shared dir, not
> `~/.openclaw/shared`. The playbook fails fast if you set `vision`/`vision_file`
> for such a team — set the mission inside that team's own files instead.

See [`inventory/README.md`](inventory/README.md) for the full layout,
layering rules, and secrets guidance (Ansible Vault / `-e` injection).

---

## Iteration loop

Edit team data in the repo → `ansible-playbook -i ansible/inventory/...
ansible/openclaw-team.yml` → bots update on every targeted host. The
playbook rsyncs the repo (excluding `.git`, `.env`, backups), re-runs
the deployer (idempotent), then reloads the gateway. A no-change run is
a near-no-op diff.

---

## What lives where

| Need                       | Use                                                                                  |
| -------------------------- | ------------------------------------------------------------------------------------ |
| One-host deploy            | `bootstrap.sh` + `install-team.sh` (the headline flow)                               |
| Fleet deploy               | These playbooks + `ansible/inventory/`                                               |
| BWS secrets / state backup | [`../docs/advanced.md`](../docs/advanced.md) — both patterns ship in `~/git/DigitalOcean_setup/openclaw` |
