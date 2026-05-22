# Ansible (optional)

The shell scripts at the repo root (`bootstrap.sh`, `install-team.sh`, and each
team's `setup.sh`) are the primary deployment path. The two playbooks here
mirror the same flow for power users running against a fleet of droplets.

If you're deploying a single droplet, **use the shell flow** — open
[DO-SETUP.md](../DO-SETUP.md). If you're deploying many droplets, or you want
declarative inventory, use these playbooks.

---

## Requirements

- Ansible 2.14+
- A target inventory with SSH access as a sudo-capable user
- Ubuntu 24.04 on the targets

---

## Playbooks

### `bootstrap.yml`

Equivalent to `bootstrap.sh` — hardens the server, creates the `openclaw` and
`claude` users, installs Node.js 22, and provisions Caddy with TLS.

Run as root (or via `become: true`):

```bash
ansible-playbook -i hosts ansible/bootstrap.yml -l droplets \
  -e admin_user=szewong \
  -e domain=teams.example.com
```

Variables:
- `admin_user` — admin SSH username (default: random `zuser-XXXX`)
- `ssh_key` — admin SSH public key (default: copy from root's authorized_keys)
- `domain` — Let's Encrypt domain; omit for self-signed TLS

### `openclaw-team.yml`

Equivalent to running `install-team.sh --team <name>` as the `openclaw` user.
Deploys agent workspaces, merges `openclaw.json`, and reloads the gateway.

```bash
ansible-playbook -i hosts ansible/openclaw-team.yml -l droplets \
  -e team=operator \
  -e anthropic_api_key=sk-ant-…
```

Variables:
- `team` — required; one of `accountant`, `modernizer`, `operator`,
  `product-builder`, `real-estate`, `recruiter`
- `anthropic_api_key` — optional; sets `ANTHROPIC_API_KEY` in `~/.openclaw/.env`

---

## What lives where

| Need                     | Use                                                       |
| ------------------------ | --------------------------------------------------------- |
| One-droplet deploy       | `bootstrap.sh` + `install-team.sh` (the headline flow)    |
| Fleet deploy             | These playbooks                                           |
| BWS secrets / state backup | See [`../docs/advanced.md`](../docs/advanced.md) — both patterns ship in `~/git/DigitalOcean_setup/openclaw` |
