# Dev Team — Claude Code Edition

An autonomous engineering team built around **Claude Code as the implementation surface**. The agents don't type code line-by-line — they spawn Claude Code subagents to do that. The team's job is to take a GitHub issue from filed to merged with minimal human typing.

Inspired by the [Alpha-2 Overnight Software Factory](https://github.com/szewong/DigitalOcean_Setup/tree/main/openclaw/openclaw-alpha-2) pattern: humans prioritize by day, agents code by night.

---

## Who's on the team

| Agent     | Color  | Function          | What they do |
|-----------|--------|-------------------|--------------|
| **Lead**     | 🔴 Red    | Engineering Lead  | Triages issues, decomposes epics, assigns work. **Read-only** — no code. |
| **Coder**    | 🟡 Yellow | Implementer       | Spawns Claude Code subagents (`runtime=acp, agentId=claude`) to implement each issue. Opens PRs. |
| **Shipper**  | 🟢 Green  | Release Manager   | CI/CD, deploys to staging/prod, rollbacks. Doesn't write features. |
| **Reviewer** | 🔵 Blue   | Code Reviewer     | Reads every line of every PR. **Read-only** — no code, no merges. |

## How the team works

```
Issue filed → Lead triages → Coder spawns Claude Code → PR opened
                                                         ↓
                                Reviewer reviews ←────────┘
                                       ↓
                                Lead calls merge
                                       ↓
                              Shipper promotes to staging → prod
```

1. **Issue filed.** The human (or a triage cron) files an issue on the team's primary repo.
2. **Lead triages.** Labels, decomposes if necessary, marks `ready` when scoped, assigns to Coder.
3. **Coder spawns Claude Code.** Uses the `claude-code-spawn` skill. The subagent runs as a real Claude Code session with full tool access in an isolated workspace, implements the change, commits, pushes, opens a PR.
4. **Reviewer reviews.** Line-by-line. Blocks on missing tests, off-spec implementations, regression risk. Approves or requests changes.
5. **Lead calls the merge.** Once Reviewer approves and CI is green, Lead green-lights the merge. (The actual merge is performed by the human or a merge bot — never silently by the team.)
6. **Shipper deploys.** Promotes merged code through environments. Monitors metrics. Rolls back if needed.

## Skills

| Skill | For whom | What it does |
|-------|----------|--------------|
| `claude-code-spawn` | Coder (primary), others (read-only) | Canonical pattern for spawning Claude Code subagents via the ACP runtime. |
| `github-issue-pipeline` | Coder | Autonomous cron-driven pickup of `ready`-labeled issues. The Overnight Software Factory loop. |
| `team-standup` | All | Periodic standup entries to `shared/standup-log.md`. |
| `daily-report` | All | End-of-day summary to the human. |
| `vision-sync` | Lead | Quarterly check that current work still serves `shared/VISION.md`. |

## Prerequisites

The team needs three things wired up before it can do meaningful work:

1. **A repo to own.** Set `Primary repo(s)` in any agent's `USER.md` (they're all identical — edit one, copy to the others).
2. **`ANTHROPIC_API_KEY`.** Used both by OpenClaw and by every Claude Code subagent the Coder spawns. Set in `~/.openclaw/.env` or via BWS (see [docs/advanced.md](../docs/advanced.md)).
3. **`GITHUB_TOKEN`.** A fine-grained PAT scoped to the team's repo, with `contents: write`, `pull-requests: write`, `issues: write`. Same options for storage.
4. **`acpx` plugin installed.** Provides the ACP runtime that wraps Claude Code as an OpenClaw subagent. On standard OpenClaw droplets, `openclaw install` handles this.

## Quick install

```bash
# As the openclaw user, after openclaw install:
curl -fsSL https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main/install-team.sh \
  | bash -s -- --team dev --api-key sk-ant-...
```

Then:

1. Edit `~/.openclaw/shared/VISION.md` — describe the repo you want this team to own.
2. Edit any agent's `USER.md` — set your name, timezone, GitHub username, repo.
3. (Optional) Set `GITHUB_TOKEN` in `~/.openclaw/.env`.
4. `openclaw start`.

## What this team is NOT

- **Not a teaching team.** It's not for learning AI-first development — for that, see [`product-builder/`](../product-builder/). This team assumes you already know what you want shipped and want autonomous execution.
- **Not a code generator on rails.** It doesn't bypass human judgment. The human still calls merges and reviews PRs alongside Reviewer.
- **Not safe to set loose on a production repo without supervision.** Test on a sandbox repo first. Read [`shared/skills/github-issue-pipeline/SKILL.md`](shared/skills/github-issue-pipeline/SKILL.md) for the safety boundaries.

## Related

- [`product-builder/`](../product-builder/) — the curriculum-style cousin: same 4-agent DISC pattern, but framed around teaching the AI-first workflow.
- [`docs/advanced.md`](../docs/advanced.md) — BWS secrets and state-backup patterns that pair well with autonomous mode.
- [Alpha-2 in DigitalOcean_setup](https://github.com/szewong/DigitalOcean_Setup/tree/main/openclaw/openclaw-alpha-2) — the single-agent ancestor this team descends from.
