#!/usr/bin/env node
import { readFileSync } from 'node:fs';
import { createRun } from './run.js';
import { claimStep, completeStep, failStep, resumeRun } from './step-ops.js';
import { showStatus, showSteps, showLogs } from './status.js';
import { triggerAgent } from './gateway.js';
import { getDb, getActiveRun, getSteps } from './db.js';
import { startDashboard, stopDashboard, dashboardStatus } from './server/daemonctl.js';
import { upgrade, printUpgradeResult } from './upgrade.js';

const args = process.argv.slice(2);
const cmd = args[0];

function parseFlags(argv: string[]): Record<string, string> {
  const flags: Record<string, string> = {};
  for (let i = 0; i < argv.length; i++) {
    if (argv[i].startsWith('--') && i + 1 < argv.length) {
      flags[argv[i].slice(2)] = argv[i + 1];
      i++;
    }
  }
  return flags;
}

function usage(): void {
  console.log(`legacy-mod — Legacy Modernization Orchestrator

Commands:
  run "<task>" --repo <path> --customer <name> --compliance <fw> --deployment <target>
  status                  Show current run status
  steps                   Show all pipeline steps
  logs [--limit N]        Show event log
  trigger <agent-id>      Force-trigger an agent
  resume                  Resume a failed step
  gate approve|reject --feedback "<text>"
  step claim <agent-id>   Claim pending work (used by cron)
  step complete <step-id> Complete a step (reads output from stdin)
  step fail <step-id> "<reason>"
  upgrade [--db-only] [--force]  Upgrade in-place (preserves database)
  dashboard [stop|status] [--port N]`);
}

try {
  switch (cmd) {
    case 'run': {
      const task = args[1];
      if (!task) { console.error('Usage: legacy-mod run "<task>" --repo ... --customer ...'); process.exit(1); }
      const flags = parseFlags(args.slice(2));
      const runId = createRun(task, {
        repo: flags.repo,
        customer: flags.customer,
        compliance: flags.compliance,
        deployment: flags.deployment,
      });
      console.log(`Run created: ${runId}`);
      console.log('Monitor with: legacy-mod status');
      break;
    }

    case 'status':
      showStatus();
      break;

    case 'steps':
      showSteps();
      break;

    case 'logs': {
      const flags = parseFlags(args.slice(1));
      const limit = flags.limit ? parseInt(flags.limit, 10) : 20;
      showLogs(limit);
      break;
    }

    case 'trigger': {
      const agentId = args[1];
      if (!agentId) { console.error('Usage: legacy-mod trigger <agent-id>'); process.exit(1); }
      const fullId = agentId.startsWith('legacy-mod/') ? agentId : `legacy-mod/${agentId}`;
      triggerAgent(fullId, `Check for pending work and execute.`);
      console.log(`Triggered ${fullId}`);
      break;
    }

    case 'resume': {
      const msg = resumeRun();
      console.log(msg);
      break;
    }

    case 'gate': {
      const action = args[1];
      const flags = parseFlags(args.slice(2));
      const feedback = flags.feedback ?? '';

      const run = getActiveRun();
      if (!run) { console.error('No active run.'); process.exit(1); break; }

      const steps = getSteps(run.id);
      const gateStep = steps.find(s => s.step_id.includes('gate') && (s.status === 'pending' || s.status === 'running'));
      if (!gateStep) { console.error('No gate step waiting for approval.'); process.exit(1); break; }

      const db = getDb();
      if (action === 'approve') {
        // Ensure it's running so completeStep works
        if (gateStep.status === 'pending') {
          db.prepare("UPDATE steps SET status = 'running', started_at = datetime('now') WHERE id = ?").run(gateStep.id);
        }
        const output = `STATUS: done\nCUSTOMER_APPROVED: yes\nCUSTOMER_FEEDBACK: ${feedback}`;
        completeStep(gateStep.id, output);
        db.prepare("UPDATE runs SET status = 'running', updated_at = datetime('now') WHERE id = ?").run(run.id);
        console.log(`Gate "${gateStep.step_name}" approved.`);
      } else if (action === 'reject') {
        if (gateStep.status === 'pending') {
          db.prepare("UPDATE steps SET status = 'running', started_at = datetime('now') WHERE id = ?").run(gateStep.id);
        }
        failStep(gateStep.id, feedback || 'Rejected by customer');
        console.log(`Gate "${gateStep.step_name}" rejected.`);
      } else {
        console.error('Usage: legacy-mod gate approve|reject --feedback "..."');
        process.exit(1);
      }
      break;
    }

    case 'step': {
      const subCmd = args[1];
      if (subCmd === 'claim') {
        const agentId = args[2];
        if (!agentId) { console.error('Usage: legacy-mod step claim <agent-id>'); process.exit(1); break; }
        const result = claimStep(agentId);
        if (result) {
          console.log(JSON.stringify(result));
        } else {
          console.log('NO_WORK');
        }
      } else if (subCmd === 'complete') {
        const stepId = args[2];
        if (!stepId) { console.error('Usage: legacy-mod step complete <step-id>'); process.exit(1); break; }
        const input = readFileSync(0, 'utf-8');
        completeStep(stepId, input);
        console.log('Step completed.');
      } else if (subCmd === 'fail') {
        const stepId = args[2];
        const reason = args[3] ?? 'Unknown failure';
        if (!stepId) { console.error('Usage: legacy-mod step fail <step-id> "<reason>"'); process.exit(1); break; }
        failStep(stepId, reason);
        console.log('Step failed.');
      } else {
        console.error('Usage: legacy-mod step claim|complete|fail ...');
        process.exit(1);
      }
      break;
    }

    case 'dashboard': {
      const subCmd = args[1];
      const flags = parseFlags(args.slice(1));
      const port = flags.port ? parseInt(flags.port, 10) : 3334;
      if (subCmd === 'stop') {
        stopDashboard();
      } else if (subCmd === 'status') {
        dashboardStatus();
      } else {
        startDashboard(port);
      }
      break;
    }

    case 'upgrade': {
      const dbOnly = args.includes('--db-only');
      const force = args.includes('--force');
      const result = upgrade({ dbOnly, force });
      printUpgradeResult(result);
      break;
    }

    case '--help':
    case '-h':
    case 'help':
    case undefined:
      usage();
      break;

    default:
      console.error(`Unknown command: ${cmd}`);
      usage();
      process.exit(1);
  }
} catch (e) {
  console.error(e instanceof Error ? e.message : String(e));
  process.exit(1);
}
