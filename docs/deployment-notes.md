# Deployment notes — fresh droplet, real-world gotchas

Field notes from deploying a team end-to-end onto a bare Ubuntu 24.04 DigitalOcean
droplet with a **modern Ansible (core 2.19)** controller. The happy path is in
[DO-SETUP.md](../DO-SETUP.md) and [ansible/README.md](../ansible/README.md); this
file records what actually bites you, so the next deploy is faster. If you're a Claude
Code agent doing a bootstrap, **read this first.**

---

## The full sequence (and the gap)

A fresh droplet → live team is **four steps**, not three. The middle one is easy to miss
because no playbook runs it:

1. **Provision** — `ansible/bootstrap.yml` (hardening, `openclaw`/`claude` users, Node 22, Caddy).
2. **Install the OpenClaw gateway** — *separate, not in any playbook*:
   ```bash
   ssh root@HOST 'sudo -u openclaw bash -lc "curl -fsSL https://openclaw.ai/install.sh | bash"'
   ```
   `bootstrap.yml` installs Node + creates the user but **not** the `openclaw` binary, and
   `openclaw-team.yml`'s gateway tasks assume `~/.npm-global/bin/openclaw` exists. Skip this
   and the team deploy's gateway start fails. (Candidate for a future playbook step.)
3. **Deploy the team** — `ansible/openclaw-team.yml`.
4. **Secrets + channel pairing** — for API keys resolved from Bitwarden at gateway start
   (no keys on disk), follow [secrets-bws.md](secrets-bws.md). Then approve the first
   Telegram contact: a user DMs the bot, the bot replies with a pairing code, and you run
   `openclaw pairing approve telegram <CODE>` on the droplet (as the `openclaw` user).

---

## Ansible core 2.19 compatibility

The playbooks were written for Ansible 2.14+; core **2.19** is much stricter and several
latent issues surface on a real run. **These are already fixed on `main` (PRs #41/#42)** —
they're recorded here as lessons (and as a warning if you're on an older revision):

- **`openclaw-team.yml` — "failed at splitting arguments, either an unbalanced jinja2 block or quotes".**
  The `Deploy` task embedded a Jinja `{% if %}` block plus the bash idiom
  `"${EXTRA[@]+"${EXTRA[@]}"}"` (nested quotes) inside a `shell:` scalar; 2.19's arg splitter
  rejects it. Fixed on `main` by building `--vision` via `set_fact` and a comment-free deploy
  block. *(Takeaway: don't embed `{% %}` control flow or nested quotes in a `shell:` scalar;
  precompute with `set_fact` or use `command:`/`argv`.)*
- **`bootstrap.yml` apt-lock wait hung forever.** `while fuser … &>/dev/null` — `&>` is a
  *bashism*, but Ansible runs `shell:` under `/bin/sh` = **dash**, which parses it as
  "background `fuser`" + an always-true no-op, so the loop never exits even with no lock held.
  Fixed on `main` (POSIX `>/dev/null 2>&1` / forced bash). *(Takeaway: any `shell:` using
  bash-only syntax needs `args: { executable: /bin/bash }` or POSIX syntax.)*
- **`bootstrap.yml` authorized_keys fallback** failed with `Destination directory
  /home/<admin>/.ssh does not exist` — the `copy` module won't create the parent dir. Fixed on
  `main` by creating the admin `.ssh` dir first.
- **`ansible.posix` collection.** Use **≥ 2.2.0** for core 2.19 (`main` pins ansible-core and
  installs collections via `requirements.yml`). 2.1.0's `authorized_key`/`synchronize` misbehave.

---

## The `-e key="value with spaces"` trap (this one cost the most time)

Passing an SSH public key (which contains spaces) as `-e ssh_key="ssh-ed25519 AAAA… user@host"`
**silently truncates it to `ssh-ed25519`** — Ansible's `key=value` extra-vars parser splits
on whitespace into multiple pairs. The downstream symptom is a cryptic
`authorized_key … Module failed: list index out of range` (the module receives a key with no body).

**Always pass multi-word vars via an extra-vars file or JSON, never `-e key="a b c"`:**
```bash
ansible-playbook ... -e @secrets.yml          # YAML file  ✅
ansible-playbook ... -e '{"ssh_key":"ssh-ed25519 AAAA… u@h"}'   # JSON  ✅
ansible-playbook ... -e ssh_key="ssh-ed25519 AAAA… u@h"          # TRUNCATED ❌
```
Confirm with `ansible localhost -e ssh_key="$(cat key.pub)" -m debug -a var=ssh_key` — you'll
see it cut to `"ssh-ed25519"`.

---

## Fresh-droplet timing & connection

- **First-boot apt lock.** A new DO droplet runs cloud-init / unattended-upgrades on first
  boot and holds the dpkg lock for **several minutes**. `bootstrap.yml`'s lock-wait task rides
  this out — **run bootstrap in the background**, not a foreground command with a short timeout
  (a timeout kill mid-`apt` leaves a half-provisioned box).
- **Connect as `root` for bootstrap** (`-u root`). After hardening, root key login still works
  (`PermitRootLogin prohibit-password` only disables passwords). The team deploy can also
  connect as root (it `become`s `openclaw`), avoiding a dependency on the admin user's key
  being in place yet.
- **Don't rsync secrets to hosts.** `openclaw-team.yml` rsyncs the whole repo — keep vault files
  under `ansible/secrets/` and ensure that dir (plus `*.vault.yml` and `.claude`) is excluded.

---

## Verifying a deploy

```bash
# gateway up
ssh root@HOST 'sudo -u openclaw bash -lc "systemctl --user is-active openclaw-gateway.service"'
# config valid
ssh root@HOST 'sudo -u openclaw bash -lc "openclaw config validate"'
# NO live secrets on disk (only commented template lines should match)
ssh root@HOST 'sudo -u openclaw bash -lc "grep -vE \"^[[:space:]]*#\" ~/.openclaw/.env | grep -nE \"sk-|_KEY=|_TOKEN=\" || echo NONE"'
# model + channels came up (look for: model configured / [gateway] ready / [telegram] starting provider)
ssh root@HOST 'sudo -u openclaw bash -lc "journalctl --user -u openclaw-gateway.service -n 30 --no-pager"'
```
