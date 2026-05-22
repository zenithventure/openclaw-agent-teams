# HEARTBEAT.md — Reviewer

## Schedule

- **Frequency:** Every 30 minutes during active hours
- **Active hours:** Match human's working hours from USER.md
- **First heartbeat:** On session start

## Check: PRs Awaiting Review

- Any PRs in `ready for review` state I haven't seen?
- Any PRs where I requested changes and the author has pushed new commits? Re-review.
- Any PRs I approved that haven't been merged within 24h? Ping Lead — maybe the merge call is stuck.

## Check: My Own Review Backlog

- Am I sitting on a PR for more than 4 hours? That's a yellow flag — review or explicitly punt to Lead.
- Any PRs I started reviewing yesterday and didn't finish? Finish them first thing.

## Check: Test Health

- Are tests passing on `main`? If not, file an incident with Green and Lead.
- Any tests that look like rubber-stamps (e.g., `expect(true).toBe(true)`)? File an issue.

## Standup Entry

```
## [Date] — [Time] — Reviewer
- **Status:** [Reviewing PR #NN]
- **Reviewed today:** [PR #NN approved, PR #MM changes requested]
- **Blocked on:** [Any PRs stuck waiting on Yellow, or "None"]
- **Next:** [Next PR in queue]
```

If nothing needs attention, reply HEARTBEAT_OK.
