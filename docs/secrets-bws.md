# Secrets via Bitwarden Secrets Manager — resolve at gateway start (no keys on disk)

A **complete, validated** recipe (validated against OpenClaw **2026.5.x**) for keeping
provider API keys and channel tokens out of `~/.openclaw/.env` entirely. Secrets are
resolved in-memory at gateway start through an OpenClaw **`exec` secret provider**.
This supersedes the sketch in [advanced.md](advanced.md#1-secrets-via-bitwarden-secrets-manager-bws);
the resolver it said "this repo does not ship yet" now lives at
[`../ansible/files/openclaw-bws-secret-provider.sh`](../ansible/files/openclaw-bws-secret-provider.sh).

> Paths below use the **shipped** resolver filename `openclaw-bws-secret-provider.sh`
> consistently — install it under that name and reference that same path everywhere.

## What touches disk

Nothing but the **BWS bootstrap token**. Provider keys (OpenRouter, Telegram, …) are
never written. On disk you have only:
- `~/.config/openclaw/bws.env` (chmod 600) — `BWS_ACCESS_TOKEN` + `BWS_PROJECT_ID`.
- `~/.config/openclaw/openclaw-bws-secret-provider.sh` (chmod 700) — the resolver.
- `~/.openclaw/openclaw.json` — holds *references* `{source:exec, provider:bws, id:KEY_NAME}`, not values.

> BWS projects are scoped. The project that backs an agent may differ from whatever
> `BWS_PROJECT_ID` is in your shell. Always confirm `bws secret list <project-id>` shows
> the keys you expect before wiring them.

## How OpenClaw's exec provider works (the contract)

The gateway spawns the provider command and talks to it over **stdio**, batched:
- **stdin:** `{"protocolVersion":1,"provider":"bws","ids":["OPENROUTER_API_KEY", …]}`
- **stdout:** `{"protocolVersion":1,"values":{"OPENROUTER_API_KEY":"sk-or-…"},"errors":{}}`

Key facts (OpenClaw 2026.5.x):
- The ref `id` is **not** an argv; ids arrive on stdin. With `--provider-json-only` (default
  at runtime) the command **must** emit the JSON envelope above.
- The command is spawned with a **near-empty environment** — only the vars named by
  `--provider-pass-env` (plus any `--provider-env`). So the wrapper must set its own `PATH`
  and use absolute tool paths. `bws` itself is happy with just `BWS_ACCESS_TOKEN`/`BWS_PROJECT_ID`.
- The command path must be **absolute, owned by the gateway user, not group/world-writable,
  not a symlink** (path-security check) — `~/.config/openclaw/…` + `chmod 700` satisfies it.
- SecretRef `id` for `models.providers.*.apiKey` and `channels.telegram.botToken` must match
  `^[A-Z][A-Z0-9_]{0,127}$` — i.e. the **key name** (e.g. `OPENROUTER_API_KEY`), not a UUID.

## Steps

### 0. Put the `bws` CLI on the droplet
The resolver runs *on the host*, so `bws` must exist there (it's normally only on your
controller). Easiest is to copy your controller binary (check arch/glibc — a recent build
runs fine on 24.04):
```bash
scp ~/.local/bin/bws root@HOST:/tmp/bws
ssh root@HOST 'mkdir -p /home/openclaw/.local/bin && install -m755 /tmp/bws /home/openclaw/.local/bin/bws && chown -R openclaw:openclaw /home/openclaw/.local && rm /tmp/bws && sudo -u openclaw /home/openclaw/.local/bin/bws --version'
```

### 1. Install the resolver + bootstrap creds (chmod 700 / 600, owned `openclaw`)
Install `ansible/files/openclaw-bws-secret-provider.sh` to
`~/.config/openclaw/openclaw-bws-secret-provider.sh` (chmod 700), and write
`~/.config/openclaw/bws.env` (chmod 600) with the **trading project's** token — pipe it over
stdin so it never lands in a shell history / transcript:
```bash
scp ansible/files/openclaw-bws-secret-provider.sh root@HOST:/tmp/p.sh
ssh root@HOST 'D=/home/openclaw/.config/openclaw; mkdir -p "$D"; install -m700 /tmp/p.sh "$D/openclaw-bws-secret-provider.sh"; rm /tmp/p.sh; chown -R openclaw:openclaw "$D"'

printf 'BWS_ACCESS_TOKEN=%s\nBWS_PROJECT_ID=%s\n' "$TOK" "$PID" | \
  ssh root@HOST 'umask 077; D=/home/openclaw/.config/openclaw; mkdir -p "$D"; cat > "$D/bws.env"; chown -R openclaw:openclaw "$D"; chmod 600 "$D/bws.env"'
```

### 2. Verify resolution BEFORE wiring it in
Replicate the gateway's minimal-env spawn (only the two BWS vars) and confirm output —
print lengths, never values:
```bash
ssh root@HOST 'sudo -u openclaw bash -lc '"'"'set -a; . ~/.config/openclaw/bws.env; set +a; printf "{\"protocolVersion\":1,\"ids\":[\"OPENROUTER_API_KEY\"]}" | env -i BWS_ACCESS_TOKEN="$BWS_ACCESS_TOKEN" BWS_PROJECT_ID="$BWS_PROJECT_ID" bash ~/.config/openclaw/openclaw-bws-secret-provider.sh | jq ".values|map_values(length)"'"'"''
```

### 3. systemd EnvironmentFile so the gateway can forward the creds
The gateway runs as a `systemd --user` service. Add a drop-in so it loads the BWS token and
can pass it through to the provider (the `.service.d` dir must exist — `copy`/`install`
won't create it):
```ini
# ~/.config/systemd/user/openclaw-gateway.service.d/10-bws.conf
[Service]
EnvironmentFile=%h/.config/openclaw/bws.env
```
then `systemctl --user daemon-reload`.

### 4. Define the provider and the references (run as `openclaw`)
```bash
openclaw config set secrets.providers.bws \
  --provider-source exec \
  --provider-command /home/openclaw/.config/openclaw/openclaw-bws-secret-provider.sh \
  --provider-pass-env BWS_ACCESS_TOKEN --provider-pass-env BWS_PROJECT_ID \
  --provider-json-only

openclaw config set models.providers.openrouter.apiKey \
  --ref-source exec --ref-provider bws --ref-id OPENROUTER_API_KEY

openclaw config set channels.telegram.botToken \
  --ref-source exec --ref-provider bws --ref-id TELEGRAM_BOT_TOKEN
```
`openrouter` is a **built-in** provider (models `mode: merge` keeps built-ins and refreshes
SecretRef-managed apiKeys), so you don't need a `baseUrl`.

### 5. Pick a model + enable the channel
```bash
openclaw config set agents.defaults.model "openrouter/google/gemini-3.5-flash"
openclaw config set channels.telegram.enabled true --strict-json
openclaw config validate
```

### 6. Restart + verify
```bash
systemctl --user restart openclaw-gateway.service
# logs should show: "…model configured, enabled automatically" / "[gateway] ready" / "[telegram] starting provider (@bot)"
journalctl --user -u openclaw-gateway.service --since "1 min ago" --no-pager | grep -iE 'model configured|ready|telegram|degraded|SecretProvider'
```

## Gotchas

- **`Exec provider "bws" exited with code 1` right after `config set`** is expected from the
  *old* gateway process — it has no `EnvironmentFile`-loaded BWS vars until you **restart**.
  A config reload ≠ reloading the systemd EnvironmentFile. After `systemctl restart` it clears.
- **Validate with exec:** `openclaw config set … --dry-run --allow-exec` will actually run the
  provider (needs the BWS vars in your shell — `source bws.env` first).
- `bws` output may be ANSI-colored; the shipped wrapper strips it before `jq`.
- Resolve by **key name** (the wrapper does) so rotating a secret's UUID doesn't break refs.
