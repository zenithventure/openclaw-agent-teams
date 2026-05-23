# SKILL — claude-code-spawn

**Purpose:** The canonical pattern for spawning a Claude Code session as an OpenClaw subagent. This is the team's primary leverage — **Yellow Coder** uses it for every implementation task, and **Green Shipper** uses it for runbook execution. Lead and Reviewer do not spawn Claude Code directly (see "When to use" below for why).

## When to use

- **Yellow Coder:** Implementing an issue. Spawn a subagent, hand it the issue and acceptance criterion, let it write the code. This is the team's main use of Claude Code — Coder's `openclaw.json` entry sets `defaultRuntime: "acp", defaultAgentId: "claude"` so every Coder subagent spawn lands on Claude Code by default.
- **Green Shipper:** Runbook execution ("redeploy tag v1.2.3 to staging, then curl /health every 30s for 5 minutes and report"). Shipper has the same `acp` / `claude` defaults configured.

**Reviewer and Lead do not use this skill directly:**

- **Blue Reviewer** has `subagents.allowAgents: []` — no subagent privileges at all. Reviewer reads code with `grep`/`rg` and the filesystem; if a PR is too large to read in one session, Reviewer asks Lead to split it.
- **Red Lead** can spawn subagents in principle (`allowAgents: ["*"]`) but should not run code-touching subagents directly. If Lead needs Claude Code involved (e.g. for a batch issue audit), Lead files an issue and delegates to Coder. Keeping Lead's hands off the implementation surface preserves the team's separation of decision-making from execution.

## Prerequisites

- The `acpx` plugin is installed and pointed at a global Claude Code binary. On the standard OpenClaw droplet, this is set up by `bootstrap.sh` + `openclaw install`. Verify with:

  ```bash
  which acpx claude
  ```

- `ANTHROPIC_API_KEY` is configured. Either in `~/.openclaw/.env` or — preferably — via the `exec` provider hitting BWS (see `docs/advanced.md`).
- For PR/branch operations, `GITHUB_TOKEN` is configured (same options: `.env` or BWS).

## The canonical command

```bash
openclaw subagent run \
  --runtime acp \
  --agent-id claude \
  --prompt "<the task — see prompt anatomy below>"
```

The `--runtime acp` part is what wires this into Claude Code: ACP (Agent Client Protocol) is the bridge that `acpx` exposes; `--agent-id claude` selects Claude Code as the agent on the other end.

## Prompt anatomy

A good prompt has four parts. Skip any of them and you'll iterate more than you needed to.

1. **The task** — one sentence. "Fix GitHub issue #142 in `acme/checkout-service`."
2. **The acceptance criterion** — quote it from the issue. Don't paraphrase.
3. **Context the subagent can't infer** — relevant file paths, related issues, recent decisions. *Don't* dump the whole codebase; point at the specific files.
4. **The expected output** — "Commit to branch `fix/142-stripe-webhook-retries`, push, then exit." or "Print the call graph as a markdown list, don't write any files."

Example for Yellow:

```bash
openclaw subagent run --runtime acp --agent-id claude --prompt "$(cat <<'EOF'
Fix GitHub issue #142 in acme/checkout-service.

Acceptance criterion (from the issue):
> Stripe webhook handler at app/api/webhooks/stripe/route.ts must retry up to 3 times
> on 5xx from the downstream order service, with exponential backoff (1s, 2s, 4s).
> Failed retries get logged with the webhook ID and final error.

Context:
- The downstream order service client lives at lib/order-service.ts
- We use the `pino` logger; see lib/logger.ts for the configured instance
- Tests for this route live at app/api/webhooks/stripe/route.test.ts

Expected output:
- Branch fix/142-stripe-webhook-retries is already checked out
- Implement the retry logic, add a test for the 3-retry path, run vitest, commit, push
- Open a PR with body "Closes #142" and a 3-bullet test plan
EOF
)"
```

## Anti-patterns

- **Don't spawn a subagent for one-character typos.** Edit those by hand.
- **Don't paste the whole codebase into the prompt.** Point at files; let the subagent open them.
- **Don't run more than 2 spawns per issue.** If the second spawn didn't converge, the spec is wrong — re-scope with Lead, don't try a third.
- **Don't spawn from a heartbeat.** Subagents take minutes; heartbeats should be quick. Kick off a spawn from a normal session, monitor it via memory log entries.
- **Lead doesn't spawn for code work.** If a batch task touches code, Lead files an issue and assigns to Coder rather than spawning directly.
- **Reviewer doesn't spawn at all.** `subagents.allowAgents: []` enforces this in config; the skill documents it for the reader's mental model.

## Verifying the spawn

The subagent prints its session ID and writes to its own workspace. After it exits:

```bash
git log -3 <branch>    # confirm commits landed
gh pr view <num>       # confirm PR was opened
```

If something went wrong (no commits, no PR, weird state), the subagent's log lives under `~/.openclaw/subagent-logs/`. Check there before re-spawning.

## Related

- `github-issue-pipeline` — wraps this skill in an autonomous issue-pickup loop.
- `team-standup` — for reporting what was spawned and the outcome.
