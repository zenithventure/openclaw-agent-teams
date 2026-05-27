# Ansible inventory

Committed example inventory for the `openclaw-team.yml` playbook. Pick the
environment you want to deploy and pass its directory with `-i`:

```bash
ansible-playbook -i ansible/inventory/production ansible/openclaw-team.yml
ansible-playbook -i ansible/inventory/staging    ansible/openclaw-team.yml -l staging-host-1.example.com
```

The deployer is data-driven — the playbook reads `team`, `vision` /
`vision_file`, and channel/API secrets from your inventory, then pushes
the current repo state to each host and runs `lib/deploy-team.sh`.

---

## Layout

```
inventory/
  production/
    hosts.yml                 # host groups (replace placeholders with real hosts)
    group_vars/
      all.yml                 # defaults for every host in production
    host_vars/
      <hostname>.yml          # per-host overrides — vision, team, secrets
  staging/                    # same shape as production
    ...
```

### What goes where

| Variable             | Typical location                 | Notes |
|----------------------|----------------------------------|-------|
| `team`               | `host_vars/<host>.yml` (or `group_vars/all.yml` for uniform fleets) | Name of a directory in the repo root with `openclaw.json` + `agents/`. |
| `vision`             | `host_vars/<host>.yml`           | Inline mission statement string. Generic/data teams only (see note). |
| `vision_file`        | `host_vars/<host>.yml`           | Path relative to repo root on the control machine; copied verbatim to `~/.openclaw/shared/VISION.md`. Generic/data teams only. |
| `anthropic_api_key`  | Ansible Vault or `-e` flag       | Required for the gateway to talk to Anthropic. |
| `telegram_bot_token`, `discord_bot_token`, `discord_user_id`, `slack_app_token`, `slack_bot_token` | Vault / host_vars | Channel bindings. Only set the ones this host uses. |

`vision_file` wins over `vision` when both are set. Both layer over the
`shared/VISION.md` the team ships, and re-running the playbook is how you
push edits to the fleet.

> **`vision`/`vision_file` apply to generic (data) teams only.** A team with a
> bespoke `setup.sh` that does not forward to `lib/deploy-team.sh` (currently
> only `modernizer`) stores its mission in a team-specific shared dir, not
> `~/.openclaw/shared`, and ignores `--vision`. The playbook asserts and fails
> early if you set `vision`/`vision_file` for such a team — set the mission in
> that team's own files instead.

---

## Layering rules

Standard Ansible precedence: `host_vars` > `group_vars/<group>` >
`group_vars/all`. So a fleet-wide default in `group_vars/all.yml` is
overridden by a group entry, which is overridden by a host entry.

A common pattern:
- Set `team: operator` in `group_vars/all.yml` if every host runs the same
  team.
- Set `vision` per host so each bot has its own mission.
- Keep secrets out of `group_vars/all.yml` — use Vault, or pass `-e` at
  invocation time.

---

## Secrets

**Never commit plaintext API keys.** Two supported patterns:

1. **Ansible Vault** (recommended for committed state):
   ```bash
   ansible-vault encrypt_string 'sk-ant-...' --name anthropic_api_key \
     >> ansible/inventory/production/host_vars/example-host-1.example.com.yml
   ansible-playbook -i ansible/inventory/production ansible/openclaw-team.yml --ask-vault-pass
   ```

2. **`-e` injection** (for one-off / CI runs):
   ```bash
   ansible-playbook -i ansible/inventory/production ansible/openclaw-team.yml \
     -e anthropic_api_key="$ANTHROPIC_API_KEY"
   ```

For Bitwarden Secrets Manager (BWS) integration, see
[`../../docs/advanced.md`](../../docs/advanced.md).

---

## Targeting subsets

```bash
# Whole production fleet
ansible-playbook -i ansible/inventory/production ansible/openclaw-team.yml

# One host
ansible-playbook -i ansible/inventory/production ansible/openclaw-team.yml \
  -l example-host-1.example.com

# A subgroup (if you add `support_desks:` under `openclaw_hosts:`)
ansible-playbook -i ansible/inventory/production ansible/openclaw-team.yml \
  -l support_desks
```

Re-running against the same host(s) is how you roll out an edit. The
playbook rsyncs the repo and re-runs the deployer — idempotent, so a
no-change run is a near-no-op.
