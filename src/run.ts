import { randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { homedir } from 'node:os';
import { parseYaml } from './yaml.js';
import { getDb, emitEvent } from './db.js';
import { createCronJob } from './gateway.js';

interface WorkflowStep {
  id: string;
  name: string;
  agent: string;
  type?: string;
  input: string;
  expects?: string;
  loop?: Record<string, unknown>;
  on_fail?: Record<string, unknown>;
}

function buildCronPrompt(agentId: string): string {
  const cliPath = join(homedir(), '.openclaw', 'workspace', 'legacy-mod', 'dist', 'cli.js');
  return `You are a Legacy Modernization workflow agent. Check for pending work.

Step 1 — Check for work:
  node ${cliPath} step claim "${agentId}"

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
  cat /tmp/legacy-mod-output.txt | node ${cliPath} step complete "<stepId>"

If the work FAILED:
  node ${cliPath} step fail "<stepId>" "description of failure"

IMPORTANT: You MUST call step complete or step fail before ending your session.`;
}

export interface RunOptions {
  repo?: string;
  customer?: string;
  compliance?: string;
  deployment?: string;
}

export function createRun(task: string, options: RunOptions): string {
  const workflowPath = join(homedir(), '.openclaw', 'workspace', 'legacy-mod', 'workflows', 'legacy-mod', 'workflow.yml');
  let src: string;
  try {
    src = readFileSync(workflowPath, 'utf-8');
  } catch {
    // Fallback: try relative to script dir
    const altPath = join(process.cwd(), 'workflows', 'legacy-mod', 'workflow.yml');
    src = readFileSync(altPath, 'utf-8');
  }

  const workflow = parseYaml(src);
  const runId = randomUUID();
  const db = getDb();

  // Build initial context from workflow defaults + CLI options
  const defaultCtx = (workflow.context ?? {}) as Record<string, string>;
  const context: Record<string, string> = {
    ...defaultCtx,
    ...(options.repo ? { repo: options.repo } : {}),
    ...(options.customer ? { customer: options.customer } : {}),
    ...(options.compliance ? { compliance: options.compliance } : {}),
    ...(options.deployment ? { deployment: options.deployment } : {}),
  };

  // Insert run
  db.prepare(
    'INSERT INTO runs (id, task, status, context) VALUES (?, ?, ?, ?)'
  ).run(runId, task, 'running', JSON.stringify(context));

  // Insert steps
  const steps = (workflow.steps ?? []) as WorkflowStep[];
  const agentPrefix = 'legacy-mod/';
  const seenAgents = new Set<string>();

  for (let i = 0; i < steps.length; i++) {
    const s = steps[i];
    const stepUuid = randomUUID();
    const fullAgentId = s.agent.startsWith(agentPrefix) ? s.agent : agentPrefix + s.agent;
    const maxRetries = (s.on_fail as Record<string, unknown>)?.max_retries ?? 2;
    const stepType = s.type ?? 'single';
    const loopConfig = s.loop ? JSON.stringify(s.loop) : null;

    db.prepare(`
      INSERT INTO steps (id, run_id, step_id, step_name, agent_id, step_index,
        input_template, expects, status, max_retries, type, loop_config)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      stepUuid, runId, s.id, s.name, fullAgentId, i,
      s.input, s.expects ?? null, i === 0 ? 'pending' : 'waiting',
      maxRetries as number, stepType, loopConfig
    );

    seenAgents.add(fullAgentId);
  }

  // Create cron jobs for each unique agent
  for (const agentId of seenAgents) {
    createCronJob(agentId, buildCronPrompt(agentId));
  }

  emitEvent(runId, 'run.started', undefined, undefined, { task });
  if (steps.length > 0) {
    emitEvent(runId, 'step.pending', steps[0].id);
  }

  return runId;
}
