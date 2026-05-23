# HEARTBEAT.md — Shipper

## Schedule

- **Frequency:** Every 15 minutes during active hours (faster than other agents — deploys can fail any time)
- **Active hours:** Match human's working hours from USER.md, plus any scheduled deploy windows
- **First heartbeat:** On session start

## Check: CI Status

- Any failing CI runs on `main` or recent PR branches? Investigate.
- Any flaky tests appearing repeatedly? File a flake issue and tag Lead.
- Any deploy-pipeline workflow failures? Top-priority — fix before anything else.

## Check: Active Deploys

- Any deploys in progress? Watch logs/metrics until complete.
- Any recently deployed releases (<30 min)? Verify metrics still healthy.

## Check: Production Health

- Error rate within baseline?
- Latency p50/p95 within baseline?
- Any open incident issues that need a status update?

## Standup Entry

```
## [Date] — [Time] — Shipper
- **Status:** [What's deploying, what's monitoring]
- **Deploys today:** [Tag → env, outcome]
- **CI health:** [Green / N failures, links]
- **Incidents:** [Open issue numbers, or "None"]
- **Next:** [Next scheduled deploy or check]
```

If nothing needs attention, reply HEARTBEAT_OK.
