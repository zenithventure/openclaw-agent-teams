# Advanced setup (optional)

The three-step DigitalOcean flow on the [landing page](https://teams.zenithstudio.app)
covers everything you need to run a team on a hardened droplet. Two further
patterns — used in production by the sister `DigitalOcean_setup/openclaw` Ansible
playbooks — are documented here for power users.

Both paths are **optional**. Skip them unless you specifically need what they
provide.

---

## Secrets — choosing an approach

For the Ansible **fleet** flow there are three ways to get keys onto hosts,
in rough order of weight:

| Approach | Keys on disk? | Best for | Where |
|----------|---------------|----------|-------|
| **`-e` / env injection** | yes (`~/.openclaw/.env`) | one-off and CI runs | [`ansible/inventory/README.md`](../ansible/inventory/README.md#secrets) |
| **Ansible Vault** | yes (`~/.openclaw/.env`) | committed per-host secrets in inventory | [`ansible/inventory/README.md`](../ansible/inventory/README.md#secrets) |
| **Bitwarden Secrets Manager (BWS)** | **no** (resolved at gateway start) | single rotation point, no plaintext on disk | section 1 below |

Vault and `-e` are the defaults for the inventory model and are documented with
the playbook. BWS (below) is the heavier option when you don't want keys written
to the droplet at all. **Never commit plaintext keys** in `host_vars` /
`group_vars` regardless of which you pick.

---

## 1. Secrets via Bitwarden Secrets Manager (BWS)

Keeps API keys out of `~/.openclaw/.env` entirely. Secrets are resolved at gateway
startup through the `exec` provider rather than being written to disk.

### When to use it

- You don't want plaintext keys on the droplet's filesystem.
- You're running multiple droplets and want a single rotation point.
- You need an audit log of which key was read when.

This repo ships the resolver: [`lib/openclaw-bws-resolver.mjs`](../lib/openclaw-bws-resolver.mjs).
Each agent developer brings their **own** BWS project + access token; the secret-id
naming convention below is shared so every deployment's `openclaw.json` looks the same.

#### 1. Store your keys in BWS (per developer)

Create a Bitwarden Secrets Manager organization + project and a machine-account
access token. Store each credential as a secret whose **key** follows this
convention (the resolver matches on the secret's `key` field):

| Credential | BWS secret key |
|------------|----------------|
| Model provider API key | `openclaw/providers/<provider>/apiKey` (e.g. `.../openrouter/apiKey`) |
| Channel bot token | `openclaw/channels/<channel>/botToken` (e.g. `.../telegram/botToken`) |

#### 2. Install the resolver + token on the droplet

```bash
install -m 0755 lib/openclaw-bws-resolver.mjs /usr/local/bin/openclaw-bws-resolver.mjs
install -d -m 0700 ~/.config/openclaw
printf 'BWS_ACCESS_TOKEN=%s\n' "$YOUR_TOKEN" > ~/.config/openclaw/bws.env   # mode 600
chmod 600 ~/.config/openclaw/bws.env
```

Add an `EnvironmentFile=` to the gateway's user systemd unit so the token (the
one secret that lives on disk) loads at start:

```ini
[Service]
EnvironmentFile=%h/.config/openclaw/bws.env
```

#### 3. Declare the provider + SecretRefs in `openclaw.json`

```json5
{
  secrets: { providers: { bws: {
    source: "exec",
    command: "/usr/local/bin/openclaw-bws-resolver.mjs",
    passEnv: ["BWS_ACCESS_TOKEN", "PATH", "BWS_BIN", "BWS_PROJECT_ID"],
    jsonOnly: true,
  } } },
  models: { providers: { openrouter: {
    apiKey: { source: "exec", provider: "bws", id: "openclaw/providers/openrouter/apiKey" },
  } } },
  channels: { telegram: {
    enabled: true,
    botToken: { source: "exec", provider: "bws", id: "openclaw/channels/telegram/botToken" },
  } },
}
```

At gateway start every SecretRef is resolved (the gateway batches all ids into
one resolver call); resolution failure keeps the previous working snapshot.
`openclaw secrets reload` re-resolves without a restart. The resolver's I/O
contract (stdin `{ids:[…]}` → stdout `{values:{…}}`) and which fields accept a
SecretRef are documented at
<https://docs.openclaw.ai/gateway/secrets> and
<https://docs.openclaw.ai/reference/secretref-credential-surface>.

The resolver reads `BWS_ACCESS_TOKEN` (required), `BWS_BIN` (default `bws`), and
optional `BWS_PROJECT_ID` to scope the listing. It runs `bws secret list` once
and maps each requested id to the matching secret `key` — no key value is ever
written to disk.

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
