# Orchestrator Design — `legacy-mod` CLI

A lightweight, self-contained pipeline orchestrator that runs within the
OpenClaw environment. Zero external dependencies beyond Node.js (ships
with OpenClaw) and SQLite (native in Node 22+).

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  User / Main Agent                                      │
│    legacy-mod run "task..." --repo /path --customer ... │
└──────────────────────┬──────────────────────────────────┘
                       │
                       v
┌──────────────────────────────────────────────────────────┐
│  legacy-mod CLI  (Node.js, ~500 lines)                   │
│                                                          │
│  ┌──────────┐  ┌───────────┐  ┌──────────┐  ┌────────┐ │
│  │ run      │  │ status    │  │ step ops │  │ cron   │ │
│  │ resume   │  │ steps     │  │ claim    │  │ create │ │
│  │ gate     │  │ logs      │  │ complete │  │ remove │ │
│  │ trigger  │  │           │  │ fail     │  │        │ │
│  └──────┬───┘  └───────────┘  └─────┬────┘  └───┬────┘ │
│         │                           │            │      │
│         v                           v            v      │
│  ┌──────────────────────────────────────────────────┐   │
│  │  SQLite Database  (~/.openclaw/legacy-mod.db)    │   │
│  │  ┌──────┐  ┌───────┐  ┌─────────┐  ┌─────────┐ │   │
│  │  │ runs │  │ steps │  │ modules │  │ events  │ │   │
│  │  └──────┘  └───────┘  └─────────┘  └─────────┘ │   │
│  └──────────────────────────────────────────────────┘   │
│         │                                               │
│         v                                               │
│  ┌──────────────────────────────────────────────────┐   │
│  │  OpenClaw Gateway / CLI                          │   │
│  │  - cron add/remove (agent polling)               │   │
│  │  - sessions (isolated agent execution)           │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

## SQLite Schema

```sql
-- Pipeline runs
CREATE TABLE runs (
  id          TEXT PRIMARY KEY,          -- UUID
  task        TEXT NOT NULL,             -- The task description
  status      TEXT NOT NULL DEFAULT 'running',  -- running | paused | blocked | completed | canceled | failed
  context     TEXT NOT NULL DEFAULT '{}',       -- JSON: accumulated key-value pairs flowing between steps
  created_at  TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Pipeline steps
CREATE TABLE steps (
  id              TEXT PRIMARY KEY,      -- UUID
  run_id          TEXT NOT NULL REFERENCES runs(id),
  step_id         TEXT NOT NULL,         -- Matches workflow.yml step id (e.g., "scan-codebase")
  step_name       TEXT NOT NULL,         -- Human-readable name
  agent_id        TEXT NOT NULL,         -- Which agent executes this (e.g., "legacy-mod/commander")
  step_index      INTEGER NOT NULL,      -- Order in pipeline
  input_template  TEXT NOT NULL,         -- The input prompt with {{variables}}
  expects         TEXT,                  -- Expected output pattern (e.g., "STATUS: done")
  status          TEXT NOT NULL DEFAULT 'waiting',  -- waiting | pending | running | done | failed
  output          TEXT,                  -- Agent's output after completion
  retry_count     INTEGER NOT NULL DEFAULT 0,
  max_retries     INTEGER NOT NULL DEFAULT 2,
  type            TEXT NOT NULL DEFAULT 'single',   -- single | loop | gate
  loop_config     TEXT,                  -- JSON: {over, completion, fresh_session, verify_each, verify_step}
  current_module_id TEXT,                -- For loop steps: which module is being processed
  started_at      TEXT,
  completed_at    TEXT,
  created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Migration modules (populated during Phase 2 from MIGRATION_STEPS_JSON)
CREATE TABLE modules (
  id              TEXT PRIMARY KEY,      -- UUID
  run_id          TEXT NOT NULL REFERENCES runs(id),
  module_index    INTEGER NOT NULL,      -- Order in migration sequence
  module_id       TEXT NOT NULL,         -- From workflow (e.g., "step-1")
  title           TEXT NOT NULL,
  description     TEXT,
  risk            TEXT,                  -- high | medium | low
  compliance_items TEXT,                 -- JSON array
  rollback        TEXT,                  -- Rollback strategy description
  status          TEXT NOT NULL DEFAULT 'pending',  -- pending | running | done | failed
  output          TEXT,
  retry_count     INTEGER NOT NULL DEFAULT 0,
  max_retries     INTEGER NOT NULL DEFAULT 2,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  completed_at    TEXT
);

-- Event log
CREATE TABLE events (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  run_id      TEXT NOT NULL REFERENCES runs(id),
  event_type  TEXT NOT NULL,            -- run.started, step.pending, step.running, step.done, step.failed, module.started, module.done, module.failed, pipeline.advanced, gate.waiting, gate.approved
  step_id     TEXT,
  module_id   TEXT,
  data        TEXT,                     -- JSON: additional event data
  created_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Enable WAL mode for concurrent reads
PRAGMA journal_mode = WAL;
```

## CLI Commands

### `legacy-mod run "<task>" --repo <path> --customer <name> --compliance <frameworks> --deployment <target>`

1. Parse `workflow.yml` from the module directory
2. Create a run in SQLite with context from CLI args
3. Insert all steps from the workflow, first step as `pending`, rest as `waiting`
4. Create cron jobs for each agent via OpenClaw gateway/CLI
5. Emit `run.started` event
6. Print run ID and monitoring instructions

### `legacy-mod status`

Query the active run and display:
- Current phase (LEARN / PLAN / EXECUTE)
- Current step name and status
- Completed / total steps
- If in Phase 3 loop: modules completed / total

### `legacy-mod steps`

Show all steps with their status, agent, and timing:
```
#  Step                              Agent           Status   Duration
1  Phase 1.1 — Scan Codebase        commander       done     12m
2  Phase 1.2 — Extract Business...  architect        done     18m
3  Phase 1.3 — Audit & Verify       compliance-gate  running  7m
4  Phase 1.4 — Assemble Docs        documenter       waiting
...
```

### `legacy-mod logs`

Tail the event log, most recent first.

### `legacy-mod trigger <agent-id>`

Force-run the agent's cron job immediately instead of waiting for the next cycle.
Calls OpenClaw's cron trigger API or spawns an isolated session directly.

### `legacy-mod resume`

Find the failed step, reset it to `pending`, re-enable its cron job.
For loop steps with failed modules, reset the failed module to `pending`.

### `legacy-mod gate approve --feedback "<text>"`

Complete the current gate step with the provided feedback.
Advances the pipeline to the next phase.

### `legacy-mod gate reject --feedback "<text>"`

Fail the current gate step. The run pauses until `resume` is called
after the team addresses the feedback.

## Step Operations (called by agents via cron)

### `legacy-mod step claim <agent-id>`

1. Clean up abandoned steps (running for > 15 min without completion)
2. Find a `pending` step assigned to this agent
3. If found:
   - Set status to `running`, record `started_at`
   - Resolve `{{variables}}` in the input template against the run context
   - Return JSON: `{stepId, runId, input}`
4. If not found: return `NO_WORK`

### `legacy-mod step complete <step-id>`

1. Read agent output from stdin
2. Parse `KEY: value` lines from output, merge into run context
3. For loop steps: parse `MIGRATION_STEPS_JSON` and populate the `modules` table
4. Set step status to `done`, record `completed_at`
5. Call `advancePipeline()` — promote next `waiting` step to `pending`
6. If all steps done, set run status to `completed`
7. Emit events

### `legacy-mod step fail <step-id> "<reason>"`

1. Increment retry count
2. If retries < max: set step back to `pending` (will be re-claimed next cron cycle)
3. If retries exhausted: set step to `failed`, set run to `blocked`, emit escalation event
4. For verify-each failures: store feedback in context as `verify_feedback`

## Cron Job Prompt Template

Each agent gets a cron job with this prompt (injected during `run`):

```
You are a Legacy Modernization workflow agent. Check for pending work.

Step 1 — Check for work:
  node ~/.openclaw/workspace/legacy-mod/dist/cli.js step claim "<agent-id>"

If output is "NO_WORK", reply HEARTBEAT_OK and stop.

Step 2 — If JSON is returned, read the "input" field. It contains your task.

Step 3 — Execute the task described in "input". Follow your SOUL.md and AGENTS.md.

Step 4 — MANDATORY: Report completion:
  Write your output to a temp file, then pipe it to step complete:

  cat <<'EOF' > /tmp/legacy-mod-output.txt
  STATUS: done
  KEY1: value1
  KEY2: value2
  EOF
  cat /tmp/legacy-mod-output.txt | node ~/.openclaw/workspace/legacy-mod/dist/cli.js step complete "<stepId>"

If the work FAILED:
  node ~/.openclaw/workspace/legacy-mod/dist/cli.js step fail "<stepId>" "description of failure"

IMPORTANT: You MUST call step complete or step fail before ending your session.
```

## Pipeline Advancement Logic

```
advancePipeline(runId):
  1. Find next step with status = 'waiting' ordered by step_index
  2. If found: set to 'pending', emit pipeline.advanced event
  3. If not found: set run to 'completed', emit run.completed event

  Special cases:
  - Gate steps: set run to 'blocked' until gate approve/reject is called
  - Loop steps: don't advance until all modules are 'done'
  - Verify-each: after module completion, insert verify step as 'pending'
```

## Abandoned Step Cleanup

```
cleanupAbandonedSteps():
  THRESHOLD = 15 minutes
  For each step with status = 'running' and started_at < (now - THRESHOLD):
    - If retry_count < max_retries: set to 'pending', increment retry
    - Else: set to 'failed', block the run, emit timeout event
```

## Template Variable Resolution

```
resolveTemplate(template, context):
  Replace all {{key}} with context[key]
  Replace all {{key}} with context[key.toLowerCase()] (case-insensitive fallback)
  If key not found: replace with [missing: key]
```

## File Layout After Install

```
~/.openclaw/workspace/legacy-mod/          # This repo, cloned here
  ├── dist/cli.js                          # Built orchestrator CLI
  ├── src/cli.ts                           # Orchestrator source
  ├── workflow.yml                         # Pipeline definition
  ├── setup.sh                             # One-line installer
  ├── agents/                              # Agent persona files
  ├── skills/                              # Skill definitions
  └── shared/                              # Shared skills (legacy-scan, etc.)

~/.openclaw/legacy-mod.db                  # SQLite database (created at first run)

~/.openclaw/workspaces/legacy-mod/         # Agent workspaces (created by setup.sh)
  ├── scanner/                             # Commander workspace
  ├── architect/                           # Architect workspace
  ├── documenter/                          # Documenter workspace
  ├── compliance-gate/                     # ComplianceGate workspace
  └── migrator/                            # Migrator workspace

~/.openclaw/skills/legacy-modernization/   # Skill installed for main agent
  └── SKILL.md

~/.local/bin/legacy-mod                    # CLI symlink
```

## Dependencies

- **Node.js 22+** (ships with OpenClaw, includes native `node:sqlite`)
- **OpenClaw** (for agent sessions, cron jobs, gateway API)
- **Nothing else.** No npm install, no external services, no Docker.

## Implementation Estimate

The orchestrator is ~500-700 lines of TypeScript:
- `cli.ts` — CLI argument parsing and command routing (~100 lines)
- `db.ts` — SQLite schema, migrations, queries (~100 lines)
- `run.ts` — Run creation, step insertion, cron setup (~100 lines)
- `step-ops.ts` — claim, complete, fail, advance pipeline (~150 lines)
- `gateway.ts` — OpenClaw cron/session API with CLI fallback (~80 lines)
- `template.ts` — Variable resolution (~30 lines)
- `status.ts` — Status and log queries (~50 lines)
