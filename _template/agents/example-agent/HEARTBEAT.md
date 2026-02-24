# HEARTBEAT.md — [Role Name]

<!-- ─────────────────────────────────────────────────────────
  TEMPLATE INSTRUCTIONS (delete this comment block when done):

  The heartbeat defines what this agent checks on a regular cycle.
  Think of it as a recurring self-audit: "What should I look at
  every time I wake up to make sure nothing has drifted?"

  Heartbeat frequency depends on the agent's role:
    - High-frequency roles (ops, monitoring): every 15-30 minutes
    - Standard roles (development, analysis): every 30-60 minutes
    - Low-frequency roles (reporting, compliance): every few hours

  Each check should be a concrete question the agent can answer
  by reading files, checking status, or running a command.

  The "HEARTBEAT_OK" convention: if nothing needs attention,
  the agent replies with HEARTBEAT_OK to confirm it checked.
  This keeps the standup log clean.
───────────────────────────────────────────────────────────── -->

## Schedule

- **Frequency:** Every [30] minutes during active hours
- **Active hours:** [Match human's availability from USER.md]
- **First heartbeat:** On session start, after reading all context files

## Check: [Primary Responsibility Area]

<!-- Replace with checks relevant to this agent's Core Workflow -->

- [Is the primary deliverable up to date?]
- [Any new inputs that need processing?]
- [Any blockers or stale items?]

## Check: [Team Coordination]

<!-- Replace with checks about how this agent's work connects to the team -->

- [Has another agent produced something this agent needs to act on?]
- [Is this agent blocking anyone else?]
- [Any messages or requests waiting for a response?]

## Check: [Quality / Drift]

<!-- Replace with checks about whether things have gone off track -->

- [Has anything changed that invalidates previous work?]
- [Any standards or constraints being violated?]
- [Anything that should be escalated to the human?]

## Standup Entry

At each heartbeat, if there is anything to report, write a brief entry to `shared/standup-log.md`:

```
## [Date] — [Time] — [Agent Name]
- **Status:** [What you're working on]
- **Completed:** [What's done since last heartbeat]
- **Blocked:** [Anything stuck, or "None"]
- **Next:** [What you'll do before the next heartbeat]
```

If nothing needs attention, reply HEARTBEAT_OK.
