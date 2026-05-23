---
name: daily-report
description: Compile and send a consolidated dev-team status report to the human operator. Three times daily — morning (9:00), midday (13:00), and end-of-day (17:00).
requirements:
  - Read access to shared workspace and standup logs
  - Ability to send messages to the human via configured channel
---

# Daily Report Skill (Dev Team)

You are compiling a team status report for the human operator. Reports are sent three times per day: morning, midday, and end-of-day.

## Who Compiles the Report

**Red Lead** is responsible for compiling and sending the final consolidated report. Other agents contribute their sections during the standup window preceding each report.

Fallback order if Lead is unavailable: Green Shipper → Blue Reviewer → Yellow Coder.

## Report Timing

| Report | Time | Purpose |
|--------|------|---------|
| Morning | 9:00 AM | Today's queue, what got picked up overnight (autonomous mode), deploys planned |
| Midday | 1:00 PM | Mid-day progress, PRs awaiting review, deploy status |
| End-of-Day | 5:00 PM | What shipped, what's open, what's queued for overnight or tomorrow |

_(Times are in the human's configured timezone from `USER.md`.)_

## Report Format

### Morning Report Template

```
Good morning. Here's the dev team's plan for today.

QUEUE STATUS: [N issues ready, M in flight, K awaiting human]

OVERNIGHT (autonomous mode, if enabled):
- [PR #NN opened for issue #MM, status]
- [No autonomous work / mode disabled]

TODAY'S PLAN:
1. [Issue #NN — Coder]
2. [Issue #MM — Coder]
3. [Deploy v1.2.3 to staging — Shipper]

PRs AWAITING REVIEW: [#NN, #MM] — Reviewer
PRs APPROVED + WAITING ON MERGE CALL: [#NN] — needs your call

DECISIONS NEEDED:
- [Decision 1, if any]
- None today [if none]

CI HEALTH: [Green / N failures, link]
```

### Midday Report Template

```
Midday check-in.

PROGRESS SINCE MORNING:
- [PR #NN merged]
- [Issue #MM in-flight — Claude Code session running]
- [PR #KK reviewed — changes requested]

PRs AWAITING YOUR MERGE CALL: [#NN approved + green]

BLOCKERS:
- [Blocker requiring human input, if any]
- None [if none]

DEPLOY STATUS:
- [Promoted v1.2.3 to staging — healthy]
- [Prod deploy planned for 16:00]
```

### End-of-Day Report Template

```
EOD report.

SHIPPED TODAY:
- [PR #NN — title — merged]
- [PR #MM — title — merged]

OPEN PRs:
- [PR #KK — awaiting Reviewer]
- [PR #LL — awaiting your merge call]

CARRIED OVER:
- [Issue #NN — re-spawn needed (Claude Code didn't converge)]

INCIDENTS / ROLLBACKS:
- [Any incident issues, or "None"]

OVERNIGHT QUEUE (autonomous mode):
- [N issues labeled `ready` and `no:assignee`, will be picked up after Y:00]

TOMORROW'S TOP PRIORITIES:
1. [Issue or theme]
2. [Issue or theme]

DECISIONS NEEDED BEFORE TOMORROW:
- [Items requiring you, or "None"]
```

## Report Guidelines

- **Be concise.** The human wants to scan in under 60 seconds. Details are in `standup-log.md`.
- **Be honest.** Don't hide a stuck Claude Code spawn or a flaky deploy. Surface problems with proposed next steps.
- **Speak as one team.** This is the team's report, not four reports stapled together.
- **Actionable blockers.** If you need human input, say what decision is needed and offer concrete options.
- **Quantify.** "Merged 3 of 4 ready PRs" beats "made progress."
- **Link PRs and issues.** Every reference should be clickable.

## After Sending

- Save a copy of each report to `shared/reports/YYYY-MM-DD-[morning|midday|eod].md`.
- If a Vision adjustment was implied (e.g. priorities shifted), Lead updates the Current Phase section of `VISION.md`.
- Shipper verifies the report was actually delivered to the configured channel.
