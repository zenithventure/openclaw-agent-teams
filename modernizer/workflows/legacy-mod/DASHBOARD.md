# Dashboard Design — Legacy Modernization Monitor

A lightweight web dashboard for monitoring legacy modernization progress.
Auto-starts on install. Zero external dependencies.

## Architecture

Same pattern as Antfarm's dashboard:
- Plain `node:http` server (~150 lines)
- Single self-contained `index.html` (~400 lines, no framework)
- Queries SQLite (`~/.openclaw/legacy-mod.db`) in WAL mode
- Detached daemon with PID file management
- Frontend polls every 30 seconds via `fetch()`

## Auto-Start

The dashboard starts automatically at the end of `setup.sh`:

```bash
# In setup.sh, build_orchestrator() section:
node ~/.openclaw/workspace/legacy-mod/dist/daemon.js 3334 &
```

Default port: **3334** (avoids collision with Antfarm's 3333 if both installed).

## Daemon Management

```
PID file:  ~/.openclaw/legacy-mod/dashboard.pid
Log file:  ~/.openclaw/legacy-mod/dashboard.log
```

| Action | Command |
|--------|---------|
| Auto-start | Happens on `setup.sh` and `legacy-mod run` |
| Manual start | `legacy-mod dashboard` |
| Stop | `legacy-mod dashboard stop` |
| Status | `legacy-mod dashboard status` |
| Custom port | `legacy-mod dashboard --port 8080` |

Daemon process:
1. Writes PID to `dashboard.pid`
2. Registers SIGTERM handler for clean shutdown
3. Starts HTTP server
4. Parent process detaches and exits

Liveness check: `process.kill(pid, 0)` — signal 0 tests if process is alive
without actually sending a signal. Stale PID files cleaned automatically.

## REST API Endpoints

| Method | Endpoint | Returns |
|--------|----------|---------|
| GET | `/api/status` | Current run summary: phase, step, progress percentage |
| GET | `/api/runs` | All runs, most recent first |
| GET | `/api/runs/:id` | Single run with all steps |
| GET | `/api/runs/:id/steps` | Steps for a run with status, agent, timing |
| GET | `/api/runs/:id/modules` | Migration modules (Phase 3 loop items) |
| GET | `/api/runs/:id/events` | Activity event log |
| GET | `/api/runs/:id/compliance` | Compliance matrix status |

### Response Shapes

```typescript
// GET /api/status
{
  "run_id": "uuid",
  "task": "Modernize ACME Financial...",
  "status": "running",
  "phase": "LEARN",              // LEARN | PLAN | EXECUTE | COMPLETE
  "current_step": "extract-business-logic",
  "current_step_name": "Phase 1.2 — Extract Business Logic",
  "steps_completed": 1,
  "steps_total": 13,
  "progress_percent": 8,
  "modules_completed": 0,        // Phase 3 only
  "modules_total": 0,
  "compliance_pass": 12,
  "compliance_fail": 3,
  "compliance_pending": 8
}

// GET /api/runs/:id/steps
[
  {
    "step_id": "scan-codebase",
    "step_name": "Phase 1.1 — Scan Codebase",
    "agent_id": "legacy-mod/commander",
    "status": "done",
    "duration_seconds": 720,
    "retry_count": 0,
    "output_summary": "MODULES_COUNT: 47, LANGUAGES: Java,SQL,XML"
  },
  ...
]

// GET /api/runs/:id/modules
[
  {
    "module_id": "step-1",
    "title": "Migrate auth module",
    "status": "done",
    "risk": "high",
    "compliance_items": ["CC6.1", "CC6.2", "GDPR-Art32"],
    "retry_count": 0
  },
  ...
]
```

## Frontend Design

### Layout: Phase Timeline (not Kanban)

Legacy modernization is inherently linear (LEARN → PLAN → EXECUTE),
so a **phase timeline** is more intuitive than a Kanban board.

```
┌─────────────────────────────────────────────────────────────────────┐
│  Legacy Modernization Dashboard           [Customer: ACME Corp]  ⚙ │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────┐    ┌─────────┐    ┌──────────┐                       │
│  │  LEARN  │───>│  PLAN   │───>│ EXECUTE  │                       │
│  │ ██████░ │    │ ░░░░░░░ │    │ ░░░░░░░░ │                       │
│  │  75%    │    │  0%     │    │  0%      │                       │
│  └─────────┘    └─────────┘    └──────────┘                       │
│                                                                     │
│  Phase 1: LEARN                                    Steps: 3/5      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ ✓ Scan Codebase          Commander    12m   done            │  │
│  │ ✓ Extract Business Logic  Architect    18m   done            │  │
│  │ ● Audit & Verify         CompliGate   7m    running          │  │
│  │ ○ Assemble Documentation  Documenter   —     waiting          │  │
│  │ ○ Customer Review Gate    Commander    —     waiting          │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  Key Metrics                                                        │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐               │
│  │ Modules: 47  │ │ Dead Code:   │ │ Security:    │               │
│  │              │ │   23%        │ │  4 issues    │               │
│  └──────────────┘ └──────────────┘ └──────────────┘               │
│                                                                     │
│  Activity Log                                                       │
│  10:42  Commander completed scan-codebase (47 modules found)       │
│  10:54  Architect started extract-business-logic                    │
│  11:12  Architect completed (89 business rules extracted)           │
│  11:13  ComplianceGate started audit-and-verify                     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Phase 3 View: Module Migration Tracker

When in Phase 3 (EXECUTE), the dashboard switches to show migration progress:

```
┌─────────────────────────────────────────────────────────────────────┐
│  Phase 3: EXECUTE                        Modules: 8/23  (35%)      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ ████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░  35%              │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  Module                    Risk    Compliance     Status            │
│  ─────────────────────────────────────────────────                  │
│  ✓ Auth module            HIGH    CC6.1 ✓        done (2 retries)  │
│  ✓ User profile           MED     GDPR-17 ✓      done              │
│  ✓ Payment processing     HIGH    CC6.7,PI1.1 ✓  done              │
│  ● Reporting engine       MED     —              running            │
│  ○ Notification service   LOW     GDPR-32        pending            │
│  ...                                                                │
│                                                                     │
│  Compliance Matrix                          Pass: 18  Fail: 2      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ SOC 2: CC6.1 ✓  CC6.2 ✓  CC6.3 ✓  CC6.6 ○  CC6.7 ✓       │  │
│  │        CC7.1 ✓  CC7.2 ✗  CC8.1 ✓  A1.1 ○   A1.2 ○        │  │
│  │ GDPR:  Art5 ✓   Art6 ✓   Art17 ✓  Art25 ✗  Art32 ✓        │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Features

- **Phase progress bar** — visual indicator of overall progress across all 3 phases
- **Step list** — each step with status icon (✓ done, ● running, ○ waiting, ✗ failed), agent, duration
- **Key metrics** — modules count, dead code %, security issues, compliance gaps (extracted from step outputs via context variables)
- **Module migration tracker** — Phase 3 specific: progress bar + per-module status with risk level and compliance items
- **Compliance matrix** — visual grid of SOC 2 controls and GDPR articles with pass/fail/pending status
- **Activity log** — reverse-chronological event stream
- **Light/dark mode** — system preference with manual toggle, persisted in localStorage
- **Auto-refresh** — polls every 30 seconds

### CSS Theming

```css
:root {
  --bg-primary: #fafaf9;
  --bg-card: #ffffff;
  --text-primary: #1a1a1a;
  --accent-learn: #3b82f6;     /* Blue — understanding */
  --accent-plan: #f59e0b;      /* Amber — designing */
  --accent-execute: #10b981;   /* Green — building */
  --status-done: #10b981;
  --status-running: #3b82f6;
  --status-waiting: #9ca3af;
  --status-failed: #ef4444;
  --compliance-pass: #10b981;
  --compliance-fail: #ef4444;
  --compliance-pending: #9ca3af;
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg-primary: #0f0f0f;
    --bg-card: #1a1a1a;
    --text-primary: #e5e5e5;
  }
}
```

Each phase gets its own accent color so the user can immediately see
which phase is active.

## Implementation

4 files, ~600 lines total:

| File | Lines | Purpose |
|------|-------|---------|
| `src/server/dashboard.ts` | ~150 | HTTP server, API endpoints, static file serving |
| `src/server/daemon.ts` | ~20 | Daemon entry point, PID file, SIGTERM handler |
| `src/server/daemonctl.ts` | ~80 | Start/stop/status control functions |
| `src/server/index.html` | ~400 | Self-contained frontend: HTML + CSS + vanilla JS |

No external dependencies. Uses `node:http` and `node:sqlite` built-ins.

## Integration with setup.sh

Add to `setup.sh` after the orchestrator build step:

```bash
start_dashboard() {
    log_step "Starting dashboard..."

    local pid_dir="${OPENCLAW_DIR}/legacy-mod"
    local pid_file="${pid_dir}/dashboard.pid"
    mkdir -p "${pid_dir}"

    # Check if already running
    if [[ -f "${pid_file}" ]]; then
        local pid
        pid=$(cat "${pid_file}")
        if kill -0 "${pid}" 2>/dev/null; then
            log_ok "Dashboard already running (PID ${pid})"
            return
        fi
        rm -f "${pid_file}"
    fi

    if [[ -f "${SCRIPT_DIR}/dist/daemon.js" ]]; then
        nohup node "${SCRIPT_DIR}/dist/daemon.js" 3334 \
            >> "${pid_dir}/dashboard.log" 2>&1 &
        log_ok "Dashboard started at http://localhost:3334"
    else
        log_warn "Orchestrator not built yet — dashboard not started"
    fi
}
```

Add to uninstall:

```bash
# Stop dashboard
local pid_file="${OPENCLAW_DIR}/legacy-mod/dashboard.pid"
if [[ -f "${pid_file}" ]]; then
    kill "$(cat "${pid_file}")" 2>/dev/null || true
    rm -f "${pid_file}"
fi
log_ok "Stopped dashboard"
```

## What Makes This Different from Antfarm's Dashboard

| Antfarm | Ours |
|---------|------|
| Generic Kanban board (columns = steps) | Phase timeline (LEARN → PLAN → EXECUTE) |
| Story progress (sub-tasks of a loop) | Module migration tracker with risk + compliance |
| No compliance view | Compliance matrix grid (SOC 2 + GDPR) |
| Single workflow selector | Single-purpose: legacy modernization only |
| Port 3333 | Port 3334 (can coexist with Antfarm) |

The key differentiator is the **compliance matrix view** — for financial
company customers, seeing SOC 2 controls and GDPR articles going from
red to green is the most compelling progress indicator.
