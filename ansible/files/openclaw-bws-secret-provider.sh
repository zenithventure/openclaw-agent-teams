#!/bin/bash
# OpenClaw "exec" secret provider backed by Bitwarden Secrets Manager (BWS).
#
# Wire it up with:
#   openclaw config set secrets.providers.bws \
#     --provider-source exec \
#     --provider-command <abs path to this script> \
#     --provider-pass-env BWS_ACCESS_TOKEN --provider-pass-env BWS_PROJECT_ID \
#     --provider-json-only
# then reference secrets, e.g.:
#   openclaw config set models.providers.openrouter.apiKey \
#     --ref-source exec --ref-provider bws --ref-id OPENROUTER_API_KEY
#
# Protocol (OpenClaw exec provider, protocolVersion 1):
#   stdin : {"protocolVersion":1,"provider":"bws","ids":["KEY_NAME", ...]}
#   stdout: {"protocolVersion":1,"values":{"KEY_NAME":"<secret>"},"errors":{"KEY_NAME":{"message":"…"}}}
#
# Notes:
#   * OpenClaw spawns this with a near-empty environment (only --provider-pass-env vars),
#     so we set PATH and use an absolute bws path. Requires BWS_ACCESS_TOKEN + BWS_PROJECT_ID
#     (supply them to the gateway via a systemd EnvironmentFile and pass-env, above).
#   * Resolves by secret *key name* (the ref id), so rotating a secret's UUID won't break refs.
#   * Install chmod 700, owned by the gateway user (OpenClaw enforces a not-writable-by-others,
#     absolute, non-symlink command path).
set -euo pipefail
export PATH=/usr/local/bin:/usr/bin:/bin

BWS="${BWS_BIN:-/home/openclaw/.local/bin/bws}"   # override with BWS_BIN if installed elsewhere

req="$(cat)"
mapfile -t ids < <(printf '%s' "$req" | jq -r '.ids[]?')

# One list call; filter by key name locally. bws output may carry ANSI — strip it.
all="$("$BWS" secret list "$BWS_PROJECT_ID" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')"

out='{}'
for id in "${ids[@]}"; do
  val="$(printf '%s' "$all" | jq -r --arg k "$id" 'map(select(.key==$k))[0].value // empty')"
  if [[ -n "$val" ]]; then
    out="$(printf '%s' "$out" | jq --arg i "$id" --arg v "$val" '.values[$i]=$v')"
  else
    out="$(printf '%s' "$out" | jq --arg i "$id" '.errors[$i]={message:"secret not found in BWS project"}')"
  fi
done

printf '%s\n' "$out" | jq -c '{protocolVersion:1} + .'
