import { execSync } from 'node:child_process';
import { copyFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { homedir } from 'node:os';
import { getDb, getDbPath, getSchemaVersion, getLatestSchemaVersion, type RunRow, type StepRow } from './db.js';
import { removeCronJobs, createCronJob } from './gateway.js';
import { buildCronPrompt } from './cron.js';

export interface UpgradeOptions {
  dbOnly?: boolean;
  force?: boolean;
}

interface StepResult {
  name: string;
  status: 'ok' | 'warn' | 'error';
  message: string;
}

export interface UpgradeResult {
  steps: StepResult[];
  success: boolean;
}

export function upgrade(options: UpgradeOptions = {}): UpgradeResult {
  const steps: StepResult[] = [];

  // 1. Detect active runs
  const db = getDb();
  const activeRuns = db.prepare(
    "SELECT * FROM runs WHERE status IN ('running','blocked','paused')"
  ).all() as unknown as RunRow[];

  if (activeRuns.length > 0) {
    if (!options.force) {
      steps.push({
        name: 'Detect active runs',
        status: 'warn',
        message: `${activeRuns.length} active run(s) found. Use --force to suppress this warning.`,
      });
    } else {
      steps.push({
        name: 'Detect active runs',
        status: 'ok',
        message: `${activeRuns.length} active run(s) found (--force specified).`,
      });
    }
  } else {
    steps.push({ name: 'Detect active runs', status: 'ok', message: 'No active runs.' });
  }

  // 2. Pause cron jobs
  const cronRemoved = removeCronJobs('legacy-mod/');
  if (cronRemoved) {
    steps.push({ name: 'Pause cron jobs', status: 'ok', message: 'Cron jobs removed.' });
  } else {
    steps.push({ name: 'Pause cron jobs', status: 'warn', message: 'Could not remove cron jobs (openclaw CLI not found or no jobs).' });
  }

  // 3. Backup database
  const dbPath = getDbPath();
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupPath = `${dbPath}.backup-${timestamp}`;
  try {
    db.exec('PRAGMA wal_checkpoint(TRUNCATE)');
    if (existsSync(dbPath)) {
      copyFileSync(dbPath, backupPath);
    }
    const walPath = dbPath + '-wal';
    const shmPath = dbPath + '-shm';
    if (existsSync(walPath)) copyFileSync(walPath, backupPath + '-wal');
    if (existsSync(shmPath)) copyFileSync(shmPath, backupPath + '-shm');
    steps.push({ name: 'Backup database', status: 'ok', message: `Backed up to ${backupPath}` });
  } catch (e) {
    steps.push({ name: 'Backup database', status: 'error', message: `Backup failed: ${e instanceof Error ? e.message : String(e)}` });
    return { steps, success: false };
  }

  // 4. Run migrations (already triggered by getDb(), but report version)
  const versionBefore = getSchemaVersion();
  const versionAfter = getLatestSchemaVersion();
  if (versionBefore === versionAfter) {
    steps.push({ name: 'Run migrations', status: 'ok', message: `Schema up to date (version ${versionAfter}).` });
  } else {
    steps.push({ name: 'Run migrations', status: 'ok', message: `Migrated from version ${versionBefore} to ${versionAfter}.` });
  }

  // 5. Filesystem provisioning (unless --db-only)
  if (!options.dbOnly) {
    const scriptDir = join(dirname(getDbPath()), '..', '.openclaw', 'workspace', 'legacy-mod');
    const setupPath = join(homedir(), '.openclaw', 'workspace', 'legacy-mod', 'setup.sh');
    try {
      if (existsSync(setupPath)) {
        execSync(`bash "${setupPath}" --upgrade-fs`, { stdio: 'inherit' });
        steps.push({ name: 'Filesystem provisioning', status: 'ok', message: 'setup.sh --upgrade-fs completed.' });
      } else {
        // Try relative to process.cwd()
        const altSetup = join(process.cwd(), 'setup.sh');
        if (existsSync(altSetup)) {
          execSync(`bash "${altSetup}" --upgrade-fs`, { stdio: 'inherit' });
          steps.push({ name: 'Filesystem provisioning', status: 'ok', message: 'setup.sh --upgrade-fs completed.' });
        } else {
          steps.push({ name: 'Filesystem provisioning', status: 'warn', message: 'setup.sh not found — skipped filesystem provisioning.' });
        }
      }
    } catch (e) {
      steps.push({ name: 'Filesystem provisioning', status: 'error', message: `Filesystem provisioning failed: ${e instanceof Error ? e.message : String(e)}` });
    }
  } else {
    steps.push({ name: 'Filesystem provisioning', status: 'ok', message: 'Skipped (--db-only).' });
  }

  // 6. Restore cron jobs for active runs
  if (activeRuns.length > 0) {
    const agentIds = new Set<string>();
    for (const run of activeRuns) {
      const pendingSteps = db.prepare(
        "SELECT DISTINCT agent_id FROM steps WHERE run_id = ? AND status IN ('pending','running','waiting')"
      ).all(run.id) as unknown as Array<{ agent_id: string }>;
      for (const s of pendingSteps) {
        agentIds.add(s.agent_id);
      }
    }

    let restored = 0;
    for (const agentId of agentIds) {
      const ok = createCronJob(agentId, buildCronPrompt(agentId));
      if (ok) restored++;
    }
    steps.push({ name: 'Restore cron jobs', status: 'ok', message: `Restored ${restored}/${agentIds.size} cron job(s).` });
  } else {
    steps.push({ name: 'Restore cron jobs', status: 'ok', message: 'No active runs — no cron jobs to restore.' });
  }

  const hasError = steps.some(s => s.status === 'error');
  return { steps, success: !hasError };
}

export function printUpgradeResult(result: UpgradeResult): void {
  console.log('\nUpgrade Summary:');
  for (const step of result.steps) {
    const prefix = step.status === 'ok' ? '+' : step.status === 'warn' ? '!' : 'x';
    console.log(`  ${prefix} ${step.name}: ${step.message}`);
  }
  console.log('');
  if (result.success) {
    console.log('Upgrade completed successfully.');
  } else {
    console.log('Upgrade completed with errors.');
    process.exit(1);
  }
}
