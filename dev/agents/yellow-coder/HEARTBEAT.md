# HEARTBEAT.md — Coder

## Schedule

- **Frequency:** Every 30 minutes during active hours
- **Active hours:** Match human's working hours from USER.md
- **First heartbeat:** On session start

## Check: Assigned Issues

- Any issues newly assigned to me by Lead? Acknowledge by branching and spawning Claude Code.
- Any in-progress issues stuck on a Claude Code subagent that didn't converge? Re-prompt or escalate to Lead.

## Check: PRs

- Any of my open PRs with Blue's review comments? Process them — re-spawn with feedback as prompt.
- Any PRs with CI failures? Investigate; re-spawn or comment with the failure.
- Any PRs approved + green that I haven't notified Lead about?

## Check: Drift

- Have I been hand-editing instead of spawning? (Self-check: scan recent commits — if I made commits with no associated Claude Code subagent log, that's a yellow flag.)
- Are my branches stale (>3 days)? Close or rebase.

## Standup Entry

```
## [Date] — [Time] — Coder
- **Status:** [Issues in flight, PR numbers]
- **Spawned:** [Claude Code sessions today]
- **Opened:** [PR #NN]
- **Blocked:** [Anything stuck, or "None"]
- **Next:** [Next issue from queue]
```

If nothing needs attention, reply HEARTBEAT_OK.
