# Advanced setup (optional)

The three-step DigitalOcean flow on the [landing page](https://teams.zenithstudio.app)
covers everything you need to run a team on a hardened droplet. Two further
patterns — used in production by the sister `DigitalOcean_setup/openclaw` Ansible
playbooks — are documented here for power users.

Both paths are **optional**. Skip them unless you specifically need what they
provide.

---

## 1. Secrets via Bitwarden Secrets Manager (BWS)

Keeps API keys out of `~/.openclaw/.env` entirely. Secrets are resolved at gateway
startup through the `exec` provider rather than being written to disk.

### When to use it

- You don't want plaintext keys on the droplet's filesystem.
- You're running multiple droplets and want a single rotation point.
- You need an audit log of which key was read when.

### Sketch

1. Create a Bitwarden Secrets Manager organization and project, generate an access
   token, and note its ID.
2. Store the token at `~/.config/openclaw/bws.env` (mode `600`):

   ```env
   BWS_ACCESS_TOKEN=…
   BWS_PROJECT_ID=…
   ```

3. Install a small `bws-resolver` helper on the droplet (path:
   `~/.local/bin/openclaw-bws-resolver`) that takes a secret ID and prints its
   value.
4. Add an `EnvironmentFile=` line to the user systemd unit so the token is loaded
   at gateway start:

   ```ini
   [Service]
   EnvironmentFile=%h/.config/openclaw/bws.env
   ```

5. In `~/.openclaw/openclaw.json`, replace literal keys with `exec` refs:

   ```json
   "credentials": {
     "ANTHROPIC_API_KEY": {
       "source": "exec",
       "provider": "bws",
       "id": "ANTHROPIC_API_KEY"
     }
   }
   ```

The full Ansible implementation — including the resolver script and the
provider definition — lives in
`~/git/DigitalOcean_setup/openclaw/openclaw-secrets.yml`. This repo intentionally
does not ship a resolver yet; lift it from the playbook when you need it.

---

## 2. Periodic state backup to GitHub

Pushes each agent's `memory/` and the shared workspace to a private GitHub repo on
a systemd timer. Survives droplet rebuilds.

### When to use it

- You're treating an agent as long-lived (months, not days) and don't want to lose
  memory when you rebuild the droplet.
- You want a diffable audit trail of what the agent has been writing to its
  memory.

### Sketch

1. Create a private GitHub repo for state (e.g. `myorg/openclaw-state`).
2. Generate a **fine-grained PAT scoped to that repo only**, with `contents: write`.
   Treat this as a separate token from any dev `GITHUB_TOKEN` — the backup token
   should not be able to do anything else.
3. Store it as `GITHUB_TOKEN_BACKUP` (either in `bws.env` per pattern 1, or in
   `~/.openclaw/.env`).
4. Drop a user systemd timer + service:

   ```
   ~/.config/systemd/user/openclaw-backup.service
   ~/.config/systemd/user/openclaw-backup.timer
   ```

   The service `cd`s into a clone of the state repo, rsyncs `~/.openclaw/workspace-*`
   and `~/.openclaw/shared` into it, commits with a timestamped message, and
   pushes.

5. Enable: `systemctl --user enable --now openclaw-backup.timer`.

The full Ansible implementation, including the `.bootstrap-deployed` first-run
sentinel pattern that this repo's `setup.sh` scripts now mirror, lives in
`~/git/DigitalOcean_setup/openclaw/agent-backup.yml`. Lift it from there when you
need it.

---

## Notes

- These patterns are **not** required for the three-step DO flow to work. They add
  operational robustness for long-running deployments.
- The pointers above reference the sister repo because it is the upstream truth
  for both patterns. Ports into this repo will land when they're hardened against
  fresh droplets.
