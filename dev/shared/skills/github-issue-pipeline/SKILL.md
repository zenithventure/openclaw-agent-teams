# SKILL — github-issue-pipeline

**Purpose:** Wraps the `claude-code-spawn` skill in an autonomous issue-pickup loop. Yellow Coder uses this when the human has explicitly enabled autonomous mode: new issues labeled `ready` get implemented and PR'd without further prompting.

This is the Alpha-2 / Overnight Software Factory pattern: humans prioritize by day, agents code by night.

## When to use

- The human has said "go autonomous" or set a corresponding flag in USER.md.
- The team has a healthy issue queue with well-scoped acceptance criteria (Lead's job).
- It's outside the human's active hours (default) — agents shouldn't be racing to grab issues while the human is steering manually.

## When NOT to use

- The human is actively triaging or in mid-conversation about scope.
- The repo has merge-protection rules you haven't tested against.
- You're unsure about credentials.

## The loop

Yellow runs this as a cron job (typically every 15 minutes during the autonomous window):

```
1. List open issues:
     state:open
     label:ready
     no:assignee
     repo:<the team's repo>

2. For each issue (oldest first, up to maxConcurrent):
   a. Self-assign on GitHub (so other agent instances don't double-grab)
   b. Branch: feat/<num>-<slug> (or fix/<num>-<slug> by label)
   c. Spawn Claude Code with the prompt template (see below)
   d. On subagent exit:
      - If commits + push + PR landed → comment on issue with PR link; done
      - If subagent failed → comment with error, unassign, label `needs-human`

3. Append a line to memory/pipeline-log.jsonl with timestamp, issue, outcome.
```

## Prompt template

The autonomous prompt is stricter than the interactive one — the subagent gets no follow-up. Use this template:

```
Implement GitHub issue #<NUM> in <owner>/<repo>.

Title: <issue title>
Body:
<full issue body>

Constraints:
- Branch <branch-name> is already checked out
- Run the existing test suite (npm test / go test / pytest — whichever the repo uses) before pushing
- Tests must pass; if they don't, do NOT push — exit with a failure message
- Add tests for the change you're making (happy path minimum)
- Commit with a clear message; no Co-Authored-By lines
- Push to origin, then open a PR with body "Closes #<NUM>" and a test plan
- Do NOT modify .github/workflows/, CI config, package.json scripts, or anything outside the immediate scope

Output expected: PR opened on the repo, or a failure message explaining why not.
```

## Cron setup

Use `openclaw cron create` (or your equivalent) to schedule the pipeline. Example:

```bash
openclaw cron create \
  --name issue-pipeline \
  --schedule "*/15 0-7 * * *" \
  --workspace ~/.openclaw/workspace-yellow-coder \
  --runtime acp \
  --agent-id claude \
  --prompt-file ~/.openclaw/skills/github-issue-pipeline/cron-prompt.md
```

The `0-7` part restricts the cron to night hours (configure for your timezone in the human's USER.md). The cron-prompt file should reference this SKILL.md and the autonomous-mode flag.

## State

- **Issue pickup state** lives on GitHub itself (assignee + label `in-progress`). No local state needed.
- **Pipeline history** in `memory/pipeline-log.jsonl` — one line per attempted issue. Useful for debugging and weekly reports.
- **Failures** get a `needs-human` label on the issue + a comment with the subagent's error output.

## Safety

- **Never modify CI config autonomously.** That's a vector for self-merging.
- **Never bypass branch protection.** If `main` requires reviews, the PR sits until a human (or Blue + Lead) approves and merges. Don't try to merge from the cron.
- **Never auto-merge.** Even with all checks green, the merge call is the human's (or Lead's).
- **Stop on consecutive failures.** If 3 cron runs fail in a row, label the queue, ping the human, and disable the cron until reviewed.
- **Rate limit yourself.** No more than `maxConcurrent` spawns active at once (default 2). Set higher only with the human's say-so.

## Related

- `claude-code-spawn` — the underlying spawn pattern this skill orchestrates.
- `daily-report` — summarize what the pipeline did overnight.
