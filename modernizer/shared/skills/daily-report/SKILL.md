---
name: daily-report
description: Compile and send a consolidated team report to the human. Three times daily — morning (9:00), midday (13:00), and end-of-day (17:00).
requirements:
  - Read access to shared workspace and standup logs
  - Ability to send messages to human via configured channel
---

# Daily Report Skill

You are compiling a team status report for Mr Z. Reports are sent three times per day: morning, midday, and end-of-day.

## Who Compiles the Report

**Red Commander** is responsible for compiling the final consolidated report. Other agents contribute their sections, and Commander assembles and sends it.

If Commander is unavailable, the fallback order is: Green Anchor → Blue Lens → Yellow Spark.

## Report Timing

| Report | Time | Purpose |
|--------|------|---------|
| Morning | 9:00 AM | Set the day's plan and priorities |
| Midday | 1:00 PM | Check progress and surface blockers |
| End-of-Day | 5:00 PM | Summarize results and preview tomorrow |

_(Times are in the human's configured timezone)_

## Report Format

### Morning Report Template

```
Good morning, Mr Z. Here's your team's plan for today.

VISION STATUS: [On track / Adjusting / Blocked]

TODAY'S PRIORITIES:
1. [Highest priority task] — Owner: [Agent]
2. [Second priority] — Owner: [Agent]
3. [Third priority] — Owner: [Agent]

DECISIONS NEEDED FROM YOU:
- [Decision 1, if any]
- None today [if none]

OVERNIGHT PROGRESS:
[Brief summary of any work done since last EOD report]

TEAM HEALTH: [Good / Some friction / Needs attention]
```

### Midday Report Template

```
Midday check-in, Mr Z.

PROGRESS SINCE MORNING:
- [Completed item 1]
- [Completed item 2]
- [In progress: item 3 — ETA: X]

BLOCKERS:
- [Blocker requiring human input, if any]
- None [if none]

PRIORITY CHANGES:
- [Any shifts in priority and why]
- No changes [if stable]

CREATIVE INSIGHTS (from Spark):
[One-liner if Yellow has something worth surfacing]

RISK FLAGS (from Lens):
[One-liner if Blue has identified a new risk]
```

### End-of-Day Report Template

```
EOD report, Mr Z. Here's how today went.

ACCOMPLISHED TODAY:
- [Deliverable 1]
- [Deliverable 2]
- [Deliverable 3]

CARRIED OVER TO TOMORROW:
- [Item not completed, with reason]

VISION PROGRESS: [X% toward goal / Phase N of M complete]

KEY DECISIONS MADE TODAY:
- [Decision and reasoning]

LESSONS LEARNED:
- [Process improvement or insight]

TOMORROW'S PREVIEW:
1. [Top priority for tomorrow]
2. [Second priority]
3. [Third priority]

BLOCKERS FOR TOMORROW:
- [Items needing human input before tomorrow's work can proceed]
```

## Report Guidelines

- **Be concise.** Mr Z wants to scan in under 60 seconds. Details are in the standup log if needed.
- **Be honest.** Don't hide bad news. Surface problems early with proposed solutions.
- **Consolidate.** This is ONE team report, not four individual reports. Speak as "the team."
- **Actionable blockers.** If you need human input, be specific about what decision is needed and provide options.
- **No internal drama.** Team dynamics issues are resolved internally. Only escalate to Mr Z if they're affecting output.
- **Quantify when possible.** "Completed 3 of 5 research sections" beats "made progress on research."

## After Sending

- Save a copy of each report to `shared/reports/YYYY-MM-DD-[morning|midday|eod].md`
- Update `shared/VISION.md` team working notes if the Vision status changed
- Green Anchor should verify the report was sent successfully
