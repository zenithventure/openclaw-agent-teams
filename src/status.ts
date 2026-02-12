import { getActiveRun, getSteps, getModules, getEvents, type StepRow, type EventRow } from './db.js';

function detectPhase(steps: StepRow[]): string {
  const current = steps.find(s => s.status === 'running' || s.status === 'pending');
  if (!current) {
    const allDone = steps.every(s => s.status === 'done');
    return allDone ? 'COMPLETE' : 'UNKNOWN';
  }
  const name = current.step_name.toLowerCase();
  if (name.includes('phase 1') || name.includes('learn')) return 'LEARN';
  if (name.includes('phase 2') || name.includes('plan')) return 'PLAN';
  if (name.includes('phase 3') || name.includes('execute') || name.includes('migration')) return 'EXECUTE';
  if (name.includes('gate')) {
    // Check which phase gate belongs to based on step_id
    if (current.step_id.includes('phase1')) return 'LEARN';
    if (current.step_id.includes('phase2')) return 'PLAN';
  }
  return 'EXECUTE';
}

export function showStatus(): void {
  const run = getActiveRun();
  if (!run) {
    console.log('No active run.');
    return;
  }

  const steps = getSteps(run.id);
  const modules = getModules(run.id);
  const phase = detectPhase(steps);
  const done = steps.filter(s => s.status === 'done').length;
  const current = steps.find(s => s.status === 'running' || s.status === 'pending');
  const modsDone = modules.filter(m => m.status === 'done').length;

  console.log(`Run:     ${run.id}`);
  console.log(`Task:    ${run.task}`);
  console.log(`Status:  ${run.status}`);
  console.log(`Phase:   ${phase}`);
  console.log(`Step:    ${current ? `${current.step_name} (${current.status})` : 'none'}`);
  console.log(`Progress: ${done}/${steps.length} steps`);
  if (modules.length > 0) {
    console.log(`Modules: ${modsDone}/${modules.length} migrated`);
  }
}

export function showSteps(): void {
  const run = getActiveRun();
  if (!run) {
    console.log('No active run.');
    return;
  }

  const steps = getSteps(run.id);
  const header = '#  Step                                       Agent                    Status    Duration';
  const divider = '-'.repeat(header.length);
  console.log(header);
  console.log(divider);

  for (const s of steps) {
    const idx = String(s.step_index + 1).padEnd(3);
    const name = s.step_name.padEnd(45).slice(0, 45);
    const agent = s.agent_id.replace('legacy-mod/', '').padEnd(25).slice(0, 25);
    const status = s.status.padEnd(10);
    let duration = '—';
    if (s.started_at && s.completed_at) {
      const ms = new Date(s.completed_at + 'Z').getTime() - new Date(s.started_at + 'Z').getTime();
      const min = Math.round(ms / 60000);
      duration = min > 0 ? `${min}m` : '<1m';
    } else if (s.started_at) {
      const ms = Date.now() - new Date(s.started_at + 'Z').getTime();
      const min = Math.round(ms / 60000);
      duration = `${min}m...`;
    }
    console.log(`${idx}${name}${agent}${status}${duration}`);
  }
}

export function showLogs(limit = 20): void {
  const run = getActiveRun();
  if (!run) {
    console.log('No active run.');
    return;
  }

  const events = getEvents(run.id, limit);
  if (events.length === 0) {
    console.log('No events yet.');
    return;
  }

  for (const e of events.reverse()) {
    const time = e.created_at.slice(11, 16);
    const data = e.data ? ` ${e.data}` : '';
    const step = e.step_id ? ` [${e.step_id}]` : '';
    const mod = e.module_id ? ` (module: ${e.module_id})` : '';
    console.log(`${time}  ${e.event_type}${step}${mod}${data}`);
  }
}

export function getStatusJson(runId?: string): Record<string, unknown> | null {
  const run = runId
    ? (await_sync_getRun(runId))
    : getActiveRun();
  if (!run) return null;

  const steps = getSteps(run.id);
  const modules = getModules(run.id);
  const phase = detectPhase(steps);
  const done = steps.filter(s => s.status === 'done').length;
  const current = steps.find(s => s.status === 'running' || s.status === 'pending');
  const modsDone = modules.filter(m => m.status === 'done').length;

  // Compliance stats from modules
  let compliancePass = 0, complianceFail = 0, compliancePending = 0;
  for (const m of modules) {
    if (m.compliance_items) {
      try {
        const items = JSON.parse(m.compliance_items) as string[];
        if (m.status === 'done') compliancePass += items.length;
        else if (m.status === 'failed') complianceFail += items.length;
        else compliancePending += items.length;
      } catch { /* skip */ }
    }
  }

  return {
    run_id: run.id,
    task: run.task,
    status: run.status,
    phase,
    current_step: current?.step_id ?? null,
    current_step_name: current?.step_name ?? null,
    steps_completed: done,
    steps_total: steps.length,
    progress_percent: steps.length > 0 ? Math.round((done / steps.length) * 100) : 0,
    modules_completed: modsDone,
    modules_total: modules.length,
    compliance_pass: compliancePass,
    compliance_fail: complianceFail,
    compliance_pending: compliancePending,
  };
}

// Helper to avoid async import issues — direct db access
import { getRun } from './db.js';
function await_sync_getRun(runId: string) {
  return getRun(runId);
}
