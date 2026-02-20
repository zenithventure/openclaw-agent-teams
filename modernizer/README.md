# Installation

## Quick Start (DigitalOcean)

The fastest way to get running:

1. **Deploy a DO OpenClaw droplet** from the [DigitalOcean Marketplace](https://marketplace.digitalocean.com/apps/openclaw)
2. **SSH into your droplet:**
   ```bash
   ssh root@YOUR_DROPLET_IP
   ```
3. **Download and run the team installer:**
   ```bash
   curl -sL https://raw.githubusercontent.com/zenithventure/openclaw-agent-teams/main/modernizer/do-team-install.sh | bash -s -- modernizer
   ```
4. **Open your OpenClaw dashboard** at `https://your-droplet-ip`
5. **Edit `shared/VISION.md`** with your business context
6. **Start using your agents!**

**What the installer does:**
- Unlocks execution policies (enables agents to run tools)
- Injects team configuration into the sandbox
- Deploys all agents with DISC personalities
- Restarts OpenClaw to load everything

### Advanced (Bare Metal / Self-Hosted)

If you're running OpenClaw on your own infrastructure:

```bash
./setup.sh                    # Interactive setup
./setup.sh --clean            # Wipe and reinstall
./setup.sh --help             # Show help
```

See the [OpenClaw documentation](https://docs.openclaw.ai) for installation steps.

## Security Model

### How the Agents Run

**On DigitalOcean (Recommended):**
- Agents run under a dedicated `openclaw` user (not root)
- Execution happens inside a Docker container sandbox
- Network and filesystem access are restricted by default
- Execution policies must be explicitly unlocked

**Benefits:**
- Agents cannot escalate to root or modify system config
- Cannot access files outside their workspace
- Cannot bypass network restrictions
- Governance is enforced at the system level

**On Bare Metal:**
- Agents run with permissions you explicitly grant
- More control, but also more responsibility
- We recommend the same security principles: run as non-root, use process isolation

### Governance: What Gets Unlocked

When deployed on DO, three execution policies are unlocked:

**`tools.exec.host = gateway`** — Agents need a place to execute commands on a headless server

**`tools.exec.ask = off`** — No human approval needed (no one's there to approve anyway)

**`tools.exec.security = full`** — Full capability within the sandbox (network, filesystem operations)

The sandbox boundary (Docker container, non-root user) is where the actual security lives.

---


An [OpenClaw](https://openclaw.ai) module that modernizes legacy applications through a phased, agent-driven pipeline. One-line install on any vanilla OpenClaw setup.

Built on the "no tech debt vision" — every step produces clean, tested, documented, compliant code.

## Install

```bash
git clone https://github.com/zenithventure/team-modernize.git ~/.openclaw/workspace/legacy-mod && ~/.openclaw/workspace/legacy-mod/setup.sh
```

Or tell your OpenClaw agent:

> "Clone and install the legacy modernization module from https://github.com/zenithventure/team-modernize"

The setup script handles everything: agent provisioning, skill installation, config registration, main-agent guidance injection, and CLI setup.

## What It Does

Modernizes legacy applications in three phases, with customer approval gates between each:

```
LEARN ──> [Customer Review] ──> PLAN ──> [Customer Approval] ──> EXECUTE
```

### Phase 1: LEARN (read-only — zero risk)

Agents examine the legacy codebase and produce a documentation package:

- System map (languages, frameworks, dependencies, entry points)
- Business logic extraction (domain rules, workflows, data flows per module)
- Dead code audit with confidence scores
- Security posture assessment (OWASP Top 10)
- Customer-facing System Documentation Package

No code is changed. The deliverable is documentation that the customer validates.

### Phase 2: PLAN (design only)

Agents design the target architecture and migration strategy:

- Target architecture based on customer-requested capabilities (mobile, API, etc.)
- SOC 2 Phase 2 + GDPR compliance gap analysis
- Ordered migration sequence with rollback strategies per step
- Customer-facing Migration Plan Package

### Phase 3: EXECUTE (incremental migration)

Agents migrate modules one at a time following the strangler fig pattern:

- Characterization tests capture legacy behavior before any changes
- New code runs alongside old — traffic shifts gradually
- Every step verified for compliance, security, and behavioral equivalence
- Old modules decommissioned only after new ones are proven in production

## The Agent Team

Five specialized agents, each with a distinct personality based on the [DISC model](https://en.wikipedia.org/wiki/DISC_assessment):

| Agent | Personality | Role | Can Modify Code? |
|-------|-------------|------|:---:|
| **Commander** | Red — Dominant Driver | Scans codebase, sequences migration, coordinates team, gates phases | No |
| **Architect** | Yellow — Creative Influencer | Extracts business logic, designs target architecture, maps capabilities | No |
| **Documenter** | Green — Stable Supporter | Assembles documentation, tracks compliance matrix, maintains progress | No |
| **ComplianceGate** | Blue — Analytical Thinker | Audits dead code, scans security, verifies compliance, reviews every migration step | No (enforced) |
| **Migrator** | Red — Dominant Driver | Writes modernized code, builds anti-corruption layers, runs tests | Yes |

**Tool enforcement:** The ComplianceGate agent physically cannot modify code — its `write`, `edit`, and `apply_patch` tools are denied at the system level, not just by instruction. This guarantees independent verification integrity.

## Pipeline

13 steps across 3 phases:

```
Phase 1: LEARN
  1. Scan Codebase              (Commander)
  2. Extract Business Logic     (Architect)
  3. Audit & Verify             (ComplianceGate)
  4. Assemble Documentation     (Documenter)
  5. Customer Review Gate       (Commander → human)

Phase 2: PLAN
  6. Design Architecture        (Architect)
  7. Compliance Gap Analysis    (ComplianceGate)
  8. Sequence Migration         (Commander)
  9. Assemble Migration Plan    (Documenter)
  10. Customer Approval Gate    (Commander → human)

Phase 3: EXECUTE
  11. Execute Migration         (Migrator — loop over modules, verify-each)
  12. Verify Migration Step     (ComplianceGate — per module)
  13. Final Report              (Documenter)
```

Steps self-advance via agent cron jobs polling SQLite for pending work. Phase gates pause the pipeline until the customer reviews and approves.

## Usage

### Start a modernization run

```bash
legacy-mod run "Modernize the ACME Financial trading platform (Java/Spring monolith, PostgreSQL). Customer wants: REST API layer for mobile access, SOC 2 Phase 2 + GDPR compliance, migration to AWS ECS." \
  --repo /path/to/legacy-codebase \
  --customer "ACME Financial" \
  --compliance "soc2,gdpr" \
  --deployment "cloud:aws"
```

Or tell your OpenClaw agent what you need — it knows how to craft the task and start the workflow.

### Monitor progress

```bash
legacy-mod status          # Current phase, step, progress %
legacy-mod steps           # All steps with status and timing
legacy-mod logs            # Activity event stream
```

### Dashboard

A web dashboard auto-starts on install at `http://localhost:3334`:

- Phase timeline with progress bars
- Per-step status with agent assignments and duration
- Module migration tracker (Phase 3)
- Compliance matrix grid (SOC 2 + GDPR controls, pass/fail/pending)
- Activity log

### Handle phase gates

When the pipeline reaches a customer review gate:

```bash
legacy-mod gate approve --feedback "Customer confirmed documentation is accurate"
legacy-mod gate reject --feedback "Auth module description is incomplete"
```

### Resume from failure

```bash
legacy-mod resume          # Restarts from the exact failed step
```

## Architecture

### Orchestrator

A lightweight, self-contained pipeline engine (~500 lines TypeScript):

- **SQLite** for pipeline state (runs, steps, modules, events) — WAL mode for concurrent access
- **Cron-based polling** — each agent checks for pending work every 5 minutes
- **Template variables** — context flows between steps via `{{variable}}` resolution
- **Retry with feedback** — failed verification injects specific issues into the next retry
- **Abandoned step cleanup** — 15-minute timeout detects hung agents
- **Resume from failure** — restart from any failed step

Zero external dependencies beyond Node.js (ships with OpenClaw) and `node:sqlite` (built into Node 22+).

### Skills

| Skill | Phase | Purpose |
|-------|-------|---------|
| `legacy-scan` | LEARN | 8-step protocol for codebase analysis |
| `migration-plan` | PLAN | 9-step protocol for architecture and sequencing |
| `migration-step` | EXECUTE | 9-step protocol for per-module migration with rollback |
| `compliance-check` | All | SOC 2 + GDPR verification (quick check + full audit modes) |
| `team-standup` | All | 30-minute agent coordination protocol |
| `daily-report` | All | 3x daily consolidated status reports |
| `vision-sync` | All | Alignment ritual for shared Vision document |

### What `setup.sh` Does

| Step | What |
|------|------|
| 1 | Verifies OpenClaw is installed |
| 2 | Provisions 5 agent workspaces with DISC persona files |
| 3 | Registers agents in `openclaw.json` with role-based tool deny-lists |
| 4 | Installs 8 skills into `~/.openclaw/skills/` |
| 5 | Injects guidance into main agent's `TOOLS.md` and `AGENTS.md` |
| 6 | Copies shared workspace files (Vision template, workflow.yml) |
| 7 | Builds the orchestrator CLI |
| 8 | Creates `legacy-mod` CLI symlink |

Idempotent — safe to re-run. Uninstall with `setup.sh --uninstall`.

## Compliance

The module is designed for regulated industries (financial services, healthcare, government):

- **SOC 2 Phase 2** — Trust Service Criteria mapped to technical controls at every step
- **GDPR** — Articles 5, 6, 7, 17, 20, 25, 32, 33, 35 mapped to data handling procedures
- **Compliance-by-design** — built into the pipeline, not bolted on after
- **Per-step verification** — every migration step checked against the compliance matrix
- **Audit trail** — all events logged to SQLite with timestamps

## Development

### Prerequisites

- **Node.js 22+** (required for `node:sqlite`)
- **TypeScript 5.7+** (dev dependency, installed via npm)

### Build from source

```bash
git clone https://github.com/zenithventure/team-modernize.git
cd team-modernize
npm install
npm run build
```

This compiles TypeScript to `dist/` and copies `index.html` for the dashboard. The build produces:

- `dist/cli.js` — orchestrator CLI entry point
- `dist/server/daemon.js` — dashboard daemon entry point

### Project structure

```
src/
  cli.ts              — CLI entry point, arg parsing, command routing
  db.ts               — SQLite schema, init, query helpers
  yaml.ts             — Minimal YAML parser (no external deps)
  run.ts              — Run creation, step insertion, cron setup
  step-ops.ts         — claim, complete, fail, advancePipeline, cleanup
  gateway.ts          — OpenClaw cron/session CLI wrapper (graceful fallback)
  template.ts         — {{variable}} resolution
  status.ts           — status, steps, logs display
  server/
    dashboard.ts      — HTTP server, REST API, static file serving
    daemon.ts         — Daemon entry point, PID file, signal handlers
    daemonctl.ts      — Start/stop/status control
    index.html        — Self-contained frontend (HTML + CSS + vanilla JS)
```

Zero runtime dependencies — only `node:sqlite`, `node:http`, `node:fs`, `node:path`, `node:crypto`, `node:child_process`.

## Project Status

**Current state: Fully implemented.** The orchestrator CLI, dashboard, agent personas, skills, workflow pipeline, and setup script are all written and working.

### What's included

- Orchestrator CLI with SQLite-backed pipeline state (~1800 lines TypeScript)
- Web dashboard with phase timeline, module tracker, and compliance matrix
- Agent persona files (SOUL, AGENTS, IDENTITY) for all 5 workflow agents
- 7 skill definitions with detailed protocols
- 13-step workflow.yml pipeline definition
- `setup.sh` one-line installer
- `openclaw.json` with role-based tool enforcement
- Vision template for customer engagements
- Main-agent guidance injection (TOOLS.md + AGENTS.md blocks)

## Acknowledgments

The pipeline orchestration architecture — cron-based polling, SQLite state machine, role-based tool enforcement, fresh sessions per step, verify-each loops with feedback injection, main-agent guidance injection, and the overall "one command installs a self-advancing agent team" pattern — is directly inspired by [**Antfarm**](https://github.com/snarktank/antfarm) by [snarktank](https://github.com/snarktank). Antfarm pioneered the approach of turning multi-agent AI orchestration into a declarative YAML problem with zero external infrastructure, and this project builds on those ideas for the specific domain of legacy application modernization.

## License

MIT
