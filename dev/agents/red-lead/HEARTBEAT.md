# HEARTBEAT.md — Lead

## Schedule

- **Frequency:** Every 30 minutes during active hours
- **Active hours:** Match human's working hours from USER.md
- **First heartbeat:** On session start, after reading SOUL, USER, VISION, latest memory

## Check: Issue Queue

- Any new issues opened since last heartbeat? Triage + label.
- Any issues marked `ready` that yellow-coder hasn't picked up in >2 hours? Nudge or re-prioritize.
- Any issues open >7 days with no movement? Close as stale or reschedule.

## Check: PRs in Flight

- Any PRs open >24 hours? Investigate — is it Blue's review backlog or a real blocker?
- Any PRs that Blue rejected and yellow-coder hasn't addressed? Reassign or close.
- Any PRs Green flagged as deploy-risky? Sync with Green before merging.

## Check: Drift

- Does the active sprint's work still align with `shared/VISION.md`? If it's drifting, file a vision-sync issue for next standup.
- Anything blue-reviewer or green-shipper escalated that needs my decision?

## Standup Entry

At each heartbeat, if anything moved, write a brief entry to `shared/standup-log.md`:

```
## [Date] — [Time] — Lead
- **Status:** [What you're tracking]
- **Triaged:** [#NN, #MM]
- **Assigned:** [#NN → yellow-coder]
- **Blocked:** [Anything stuck, or "None"]
- **Next:** [What you'll do before the next heartbeat]
```

If nothing needs attention, reply HEARTBEAT_OK.
