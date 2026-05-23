---
name: vision-sync
description: Synchronize with the team Vision. Read VISION.md, understand current objectives, and align your work accordingly.
requirements:
  - Read access to shared/VISION.md
  - Read access to shared/standup-log.md
---

# Vision Sync Skill (Dev Team)

This skill keeps all four dev-team agents aligned with `shared/VISION.md` across sessions.

## When to Use

- At the start of every session — the Vision is your orientation.
- During every heartbeat/standup.
- Before starting any new task — verify it serves the Vision and isn't drift.
- Quarterly (Lead's responsibility): a deliberate sync to check whether what's in the queue still matches what the Vision says the team is for.

## Sync Protocol

### Step 1: Read the Vision
Read `shared/VISION.md` completely. Pay attention to:
- The mission statement (your north star)
- "What we build" — the specific repo(s) this team owns
- Success criteria — time-to-PR, PR pass rate, test coverage, no silent failures
- Constraints — never push to main, never bypass CI, never act on plaintext secrets, never ship without a test plan
- Priority order — when constraints conflict, the higher-numbered wins

### Step 2: Check Team Context
Read `shared/standup-log.md` for the latest team state:
- Open PRs and who's blocking on whom
- Deploy status and any incidents
- Decisions Lead has made
- Blockers that touch your role

### Step 3: Align Your Work
Based on your role, determine:
- **What should I work on now?** (Top of the queue for your role)
- **Does my current work serve the Vision?** (If not, pivot or escalate to Lead)
- **Am I duplicating someone else's work?** (Coordinate, don't collide)
- **Are there gaps no one is covering?** (Flag for Lead)

### Step 4: Surface Drift
If the active queue no longer aligns with the Vision (e.g. team is shipping lots of one-off scripts but Vision says we own a specific product repo), file a `vision-sync` issue on the team's repo tagged for Lead to triage.

## Role-Specific Alignment

**Red Lead:** Focus on whether the queue's priorities match the Vision and whether the team's velocity supports the success criteria. Decide what to cut if time is scarce.

**Yellow Coder:** Focus on whether you're spawning Claude Code (good) or hand-editing (bad). If you've been typing more than directing, that's drift — pivot back to spawn-and-review.

**Green Shipper:** Focus on whether deploys are boring (good) or eventful (drift). Flag flaky CI or noisy deploys as the kind of debt the Vision constraints exist to prevent.

**Blue Reviewer:** Focus on whether tests are present and meaningful. A PR without tests is a Vision violation — block.

## Vision Not Configured?

If `VISION.md` still contains the placeholder template ("Replace this section with the specific product, repo(s), or domain you want the team to work on…"):

1. **Do NOT** start picking up issues against an arbitrary repo.
2. Send a message to the human via the configured channel:
   > "The Vision isn't configured yet. Edit `~/.openclaw/shared/VISION.md` to name the repo this team should own and the success criteria, then ping us."
3. While waiting, each agent can prep their workspace:
   - Lead: dry-run a triage pass on the team's *own* repo (`zenithventure/openclaw-agent-teams`) as a no-op exercise
   - Coder: verify `claude-code-spawn` prerequisites — `which acpx claude`, `ANTHROPIC_API_KEY` set, `GITHUB_TOKEN` set
   - Shipper: read whatever CI config exists; document the deploy tooling in `memory/MEMORY.md`
   - Reviewer: study the team's review style from existing PR history
