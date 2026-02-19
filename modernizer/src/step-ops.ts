import { randomUUID } from 'node:crypto';
import { getDb, emitEvent, getSteps, getModules, getActiveRun, type StepRow, type ModuleRow } from './db.js';
import { resolveTemplate } from './template.js';

const ABANDON_THRESHOLD_MS = 15 * 60 * 1000; // 15 minutes

// ── Cleanup ──────────────────────────────────────────────────

export function cleanupAbandonedSteps(): void {
  const db = getDb();
  const now = Date.now();
  const running = db.prepare("SELECT * FROM steps WHERE status = 'running'").all() as unknown as StepRow[];
  for (const step of running) {
    if (!step.started_at) continue;
    const started = new Date(step.started_at + 'Z').getTime();
    if (now - started < ABANDON_THRESHOLD_MS) continue;

    if (step.retry_count < step.max_retries) {
      db.prepare("UPDATE steps SET status = 'pending', retry_count = retry_count + 1, started_at = NULL WHERE id = ?").run(step.id);
      emitEvent(step.run_id, 'step.timeout', step.step_id, undefined, { retry: step.retry_count + 1 });
    } else {
      db.prepare("UPDATE steps SET status = 'failed', completed_at = datetime('now') WHERE id = ?").run(step.id);
      db.prepare("UPDATE runs SET status = 'blocked', updated_at = datetime('now') WHERE id = ?").run(step.run_id);
      emitEvent(step.run_id, 'step.failed', step.step_id, undefined, { reason: 'timeout after max retries' });
    }
  }
}

// ── Claim ────────────────────────────────────────────────────

export interface ClaimResult {
  stepId: string;
  runId: string;
  input: string;
}

export function claimStep(agentId: string): ClaimResult | null {
  cleanupAbandonedSteps();
  const db = getDb();

  const step = db.prepare(
    "SELECT * FROM steps WHERE agent_id = ? AND status = 'pending' ORDER BY step_index LIMIT 1"
  ).get(agentId) as StepRow | undefined;

  if (!step) return null;

  // Resolve template variables
  const run = db.prepare('SELECT context FROM runs WHERE id = ?').get(step.run_id) as { context: string } | undefined;
  const context = run ? JSON.parse(run.context) as Record<string, string> : {};

  // For loop steps, inject current module info
  if (step.type === 'loop' && step.current_module_id) {
    const mod = db.prepare('SELECT * FROM modules WHERE id = ?').get(step.current_module_id) as ModuleRow | undefined;
    if (mod) {
      context.current_story = mod.title;
      context.current_module = mod.title;
      const allMods = getModules(step.run_id);
      const done = allMods.filter(m => m.status === 'done');
      const remaining = allMods.filter(m => m.status !== 'done' && m.id !== mod.id);
      context.completed_stories = done.map(m => m.title).join(', ') || 'none';
      context.stories_remaining = String(remaining.length);
      context.progress = `${done.length}/${allMods.length}`;
    }
  }

  const input = resolveTemplate(step.input_template, context);

  db.prepare("UPDATE steps SET status = 'running', started_at = datetime('now') WHERE id = ?").run(step.id);
  emitEvent(step.run_id, 'step.running', step.step_id);

  return { stepId: step.id, runId: step.run_id, input };
}

// ── Complete ─────────────────────────────────────────────────

export function completeStep(stepId: string, output: string): void {
  const db = getDb();
  const step = db.prepare('SELECT * FROM steps WHERE id = ?').get(stepId) as StepRow | undefined;
  if (!step) throw new Error(`Step not found: ${stepId}`);

  // Parse KEY: value lines from output and merge into context
  const run = db.prepare('SELECT context FROM runs WHERE id = ?').get(step.run_id) as { context: string };
  const context = JSON.parse(run.context) as Record<string, string>;
  const kvPattern = /^([A-Z_]+):\s*(.+)$/gm;
  let match: RegExpExecArray | null;
  while ((match = kvPattern.exec(output)) !== null) {
    const key = match[1].toLowerCase();
    const value = match[2].trim();
    context[key] = value;
  }

  // Handle MIGRATION_STEPS_JSON — populate modules table
  if (context.migration_steps_json) {
    try {
      const stepsJson = JSON.parse(context.migration_steps_json) as Array<{
        id: string; title: string; description?: string; risk?: string;
        compliance_items?: string[]; rollback?: string;
      }>;
      // Clear existing modules for this run
      db.prepare('DELETE FROM modules WHERE run_id = ?').run(step.run_id);
      for (let i = 0; i < stepsJson.length; i++) {
        const m = stepsJson[i];
        db.prepare(`
          INSERT INTO modules (id, run_id, module_index, module_id, title, description, risk, compliance_items, rollback)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).run(
          randomUUID(), step.run_id, i, m.id, m.title,
          m.description ?? null, m.risk ?? null,
          m.compliance_items ? JSON.stringify(m.compliance_items) : null,
          m.rollback ?? null
        );
      }
      emitEvent(step.run_id, 'modules.created', step.step_id, undefined, { count: stepsJson.length });
    } catch (e) {
      console.error('[step-ops] Failed to parse MIGRATION_STEPS_JSON:', e);
    }
  }

  // Update context
  db.prepare("UPDATE runs SET context = ?, updated_at = datetime('now') WHERE id = ?").run(JSON.stringify(context), step.run_id);

  // If this is a loop step completing a module, mark the module done
  if (step.type === 'loop' && step.current_module_id) {
    db.prepare("UPDATE modules SET status = 'done', output = ?, completed_at = datetime('now') WHERE id = ?").run(output, step.current_module_id);
    emitEvent(step.run_id, 'module.done', step.step_id, step.current_module_id);
  }

  // Mark step done
  db.prepare("UPDATE steps SET status = 'done', output = ?, completed_at = datetime('now') WHERE id = ?").run(output, step.id);
  emitEvent(step.run_id, 'step.done', step.step_id);

  advancePipeline(step.run_id);
}

// ── Fail ─────────────────────────────────────────────────────

export function failStep(stepId: string, reason: string): void {
  const db = getDb();
  const step = db.prepare('SELECT * FROM steps WHERE id = ?').get(stepId) as StepRow | undefined;
  if (!step) throw new Error(`Step not found: ${stepId}`);

  // For verify-each failures, store feedback in context
  if (step.step_id === 'verify-migration-step') {
    const run = db.prepare('SELECT context FROM runs WHERE id = ?').get(step.run_id) as { context: string };
    const context = JSON.parse(run.context) as Record<string, string>;
    context.verify_feedback = reason;
    db.prepare("UPDATE runs SET context = ?, updated_at = datetime('now') WHERE id = ?").run(JSON.stringify(context), step.run_id);
  }

  const newRetry = step.retry_count + 1;
  if (newRetry < step.max_retries) {
    db.prepare("UPDATE steps SET status = 'pending', retry_count = ?, started_at = NULL WHERE id = ?").run(newRetry, step.id);
    emitEvent(step.run_id, 'step.retry', step.step_id, undefined, { reason, retry: newRetry });
  } else {
    db.prepare("UPDATE steps SET status = 'failed', retry_count = ?, completed_at = datetime('now') WHERE id = ?").run(newRetry, step.id);
    db.prepare("UPDATE runs SET status = 'blocked', updated_at = datetime('now') WHERE id = ?").run(step.run_id);
    emitEvent(step.run_id, 'step.failed', step.step_id, undefined, { reason });
  }

  // If loop step failing on a module, mark module failed
  if (step.type === 'loop' && step.current_module_id) {
    const mod = db.prepare('SELECT * FROM modules WHERE id = ?').get(step.current_module_id) as ModuleRow | undefined;
    if (mod) {
      const modRetry = mod.retry_count + 1;
      if (modRetry < mod.max_retries) {
        db.prepare("UPDATE modules SET status = 'pending', retry_count = ? WHERE id = ?").run(modRetry, mod.id);
      } else {
        db.prepare("UPDATE modules SET status = 'failed', retry_count = ?, completed_at = datetime('now') WHERE id = ?").run(modRetry, mod.id);
        emitEvent(step.run_id, 'module.failed', step.step_id, mod.id, { reason });
      }
    }
  }
}

// ── Advance Pipeline ─────────────────────────────────────────

export function advancePipeline(runId: string): void {
  const db = getDb();
  const steps = getSteps(runId);

  // Check if current done step is a loop with remaining modules
  const lastDone = [...steps].reverse().find(s => s.status === 'done');
  if (lastDone?.type === 'loop') {
    const loopConfig = lastDone.loop_config ? JSON.parse(lastDone.loop_config) as Record<string, unknown> : {};
    const modules = getModules(runId);
    const nextModule = modules.find(m => m.status === 'pending');

    if (nextModule) {
      // Check if verify_each — look at the just-done verify step or set up verify
      if (loopConfig.verify_each) {
        const verifyStepId = loopConfig.verify_step as string | undefined;
        if (verifyStepId) {
          const verifyStep = steps.find(s => s.step_id === verifyStepId);
          if (verifyStep && verifyStep.status === 'done') {
            // Verify passed for previous module, set up next module on execute step
            db.prepare("UPDATE modules SET status = 'running' WHERE id = ?").run(nextModule.id);
            db.prepare("UPDATE steps SET status = 'pending', output = NULL, started_at = NULL, completed_at = NULL, current_module_id = ? WHERE id = ?")
              .run(nextModule.id, lastDone.id);
            // Reset verify step for next cycle
            db.prepare("UPDATE steps SET status = 'waiting', output = NULL, started_at = NULL, completed_at = NULL WHERE id = ?")
              .run(verifyStep.id);
            emitEvent(runId, 'module.started', lastDone.step_id, nextModule.id);
            emitEvent(runId, 'pipeline.advanced', lastDone.step_id);
            return;
          } else if (verifyStep && verifyStep.status === 'waiting') {
            // Need to run verify step first
            db.prepare("UPDATE steps SET status = 'pending' WHERE id = ?").run(verifyStep.id);
            emitEvent(runId, 'pipeline.advanced', verifyStepId);
            return;
          }
        }
      } else {
        // No verify, just advance to next module
        db.prepare("UPDATE modules SET status = 'running' WHERE id = ?").run(nextModule.id);
        db.prepare("UPDATE steps SET status = 'pending', output = NULL, started_at = NULL, completed_at = NULL, current_module_id = ? WHERE id = ?")
          .run(nextModule.id, lastDone.id);
        emitEvent(runId, 'module.started', lastDone.step_id, nextModule.id);
        emitEvent(runId, 'pipeline.advanced', lastDone.step_id);
        return;
      }
    }
    // All modules done or no modules yet — fall through to advance normally
  }

  // Also handle verify step completing — cycle back to execute
  const lastDoneVerify = [...steps].reverse().find(s => s.status === 'done' && s.step_id === 'verify-migration-step');
  if (lastDoneVerify) {
    const executeStep = steps.find(s => s.step_id === 'execute-migration');
    if (executeStep && executeStep.status === 'done') {
      const modules = getModules(runId);
      const nextModule = modules.find(m => m.status === 'pending');
      if (nextModule) {
        db.prepare("UPDATE modules SET status = 'running' WHERE id = ?").run(nextModule.id);
        db.prepare("UPDATE steps SET status = 'pending', output = NULL, started_at = NULL, completed_at = NULL, current_module_id = ? WHERE id = ?")
          .run(nextModule.id, executeStep.id);
        db.prepare("UPDATE steps SET status = 'waiting', output = NULL, started_at = NULL, completed_at = NULL WHERE id = ?")
          .run(lastDoneVerify.id);
        emitEvent(runId, 'module.started', executeStep.step_id, nextModule.id);
        emitEvent(runId, 'pipeline.advanced', executeStep.step_id);
        return;
      }
    }
  }

  // Standard advancement: find next waiting step
  const nextWaiting = steps.find(s => s.status === 'waiting');
  if (nextWaiting) {
    // Gate detection: if this is a gate step, block run
    if (nextWaiting.step_id.includes('gate')) {
      db.prepare("UPDATE steps SET status = 'pending' WHERE id = ?").run(nextWaiting.id);
      db.prepare("UPDATE runs SET status = 'blocked', updated_at = datetime('now') WHERE id = ?").run(runId);
      emitEvent(runId, 'gate.waiting', nextWaiting.step_id);
      return;
    }

    // If loop step, set up first module
    if (nextWaiting.type === 'loop') {
      const modules = getModules(runId);
      const firstModule = modules.find(m => m.status === 'pending');
      if (firstModule) {
        db.prepare("UPDATE modules SET status = 'running' WHERE id = ?").run(firstModule.id);
        db.prepare("UPDATE steps SET status = 'pending', current_module_id = ? WHERE id = ?")
          .run(firstModule.id, nextWaiting.id);
        emitEvent(runId, 'module.started', nextWaiting.step_id, firstModule.id);
      } else {
        db.prepare("UPDATE steps SET status = 'pending' WHERE id = ?").run(nextWaiting.id);
      }
    } else {
      db.prepare("UPDATE steps SET status = 'pending' WHERE id = ?").run(nextWaiting.id);
    }
    emitEvent(runId, 'pipeline.advanced', nextWaiting.step_id);
    return;
  }

  // No more steps — check if all done
  const allDone = steps.every(s => s.status === 'done');
  if (allDone) {
    db.prepare("UPDATE runs SET status = 'completed', updated_at = datetime('now') WHERE id = ?").run(runId);
    emitEvent(runId, 'run.completed');
  }
}

// ── Resume ───────────────────────────────────────────────────

export function resumeRun(): string {
  const run = getActiveRun();
  if (!run) return 'No active run found.';

  const db = getDb();
  const failedStep = db.prepare(
    "SELECT * FROM steps WHERE run_id = ? AND status = 'failed' ORDER BY step_index LIMIT 1"
  ).get(run.id) as StepRow | undefined;

  if (!failedStep) return 'No failed step to resume.';

  db.prepare("UPDATE steps SET status = 'pending', retry_count = 0, started_at = NULL, completed_at = NULL WHERE id = ?").run(failedStep.id);
  db.prepare("UPDATE runs SET status = 'running', updated_at = datetime('now') WHERE id = ?").run(run.id);
  emitEvent(run.id, 'step.resumed', failedStep.step_id);

  // If loop step with failed module, reset that too
  if (failedStep.type === 'loop' && failedStep.current_module_id) {
    db.prepare("UPDATE modules SET status = 'pending', retry_count = 0, completed_at = NULL WHERE id = ?").run(failedStep.current_module_id);
  }

  return `Resumed step "${failedStep.step_name}" (${failedStep.step_id})`;
}
