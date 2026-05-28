#!/usr/bin/env node
// ============================================================
// OpenClaw exec secrets resolver for Bitwarden Secrets Manager (BWS)
// ============================================================
// Implements OpenClaw's exec-provider I/O contract so API keys and channel
// tokens never touch the droplet's disk — they're fetched from BWS at gateway
// start and held in memory. Reference it from openclaw.json:
//
//   secrets: { providers: { bws: {
//     source: "exec",
//     command: "/usr/local/bin/openclaw-bws-resolver.mjs",
//     passEnv: ["BWS_ACCESS_TOKEN", "PATH", "BWS_BIN", "BWS_PROJECT_ID"],
//     jsonOnly: true } } }
//
// then resolve any SecretRef-capable field, e.g.:
//   models.providers.openrouter.apiKey:
//     { source: "exec", provider: "bws", id: "openclaw/providers/openrouter/apiKey" }
//   channels.telegram.botToken:
//     { source: "exec", provider: "bws", id: "openclaw/channels/telegram/botToken" }
//
// Contract (https://docs.openclaw.ai/gateway/secrets):
//   stdin : { "protocolVersion": 1, "provider": "bws", "ids": ["<key>", ...] }
//   stdout: { "protocolVersion": 1, "values": { "<key>": "<secret>" },
//             "errors": { "<key>": { "message": "..." } } }   // errors optional
//
// The requested `ids` are matched against each BWS secret's `key` field. The
// gateway batches ids into one call, so we list once and map by key.
//
// Env:
//   BWS_ACCESS_TOKEN  required — the BWS machine-account token (read by `bws`)
//   BWS_BIN           optional — path to the bws CLI (default: "bws")
//   BWS_PROJECT_ID    optional — scope `secret list` to one project
// ============================================================

import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";

const PROTOCOL = 1;

function readStdin() {
  try {
    return readFileSync(0, "utf8");
  } catch {
    return "";
  }
}

function fail(message) {
  // Protocol-level failure: no values, a single synthetic error. The gateway
  // keeps its previous working snapshot when resolution fails.
  process.stdout.write(JSON.stringify({ protocolVersion: PROTOCOL, values: {}, errors: { "*": { message } } }) + "\n");
  process.exit(0);
}

let req;
const raw = readStdin();
try {
  req = JSON.parse(raw || "{}");
} catch {
  fail("resolver: stdin was not valid JSON");
}

const ids = Array.isArray(req.ids) ? req.ids : [];
if (ids.length === 0) {
  process.stdout.write(JSON.stringify({ protocolVersion: PROTOCOL, values: {} }) + "\n");
  process.exit(0);
}

if (!process.env.BWS_ACCESS_TOKEN) {
  fail("resolver: BWS_ACCESS_TOKEN is not set");
}

const bws = process.env.BWS_BIN || "bws";
const args = ["secret", "list", "--output", "json"];
if (process.env.BWS_PROJECT_ID) args.splice(2, 0, process.env.BWS_PROJECT_ID);

let listed;
try {
  const out = execFileSync(bws, args, { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
  listed = JSON.parse(out);
} catch (e) {
  fail(`resolver: '${bws} secret list' failed: ${(e && e.message) || e}`);
}

// Map BWS secret key -> value. `bws secret list` yields [{ key, value, ... }].
const byKey = new Map();
for (const s of Array.isArray(listed) ? listed : []) {
  if (s && typeof s.key === "string") byKey.set(s.key, s.value);
}

const values = {};
const errors = {};
for (const id of ids) {
  if (byKey.has(id)) values[id] = byKey.get(id);
  else errors[id] = { message: "not found in BWS (no secret with this key)" };
}

const resp = { protocolVersion: PROTOCOL, values };
if (Object.keys(errors).length > 0) resp.errors = errors;
process.stdout.write(JSON.stringify(resp) + "\n");
