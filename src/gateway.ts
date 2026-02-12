import { execSync } from 'node:child_process';

function findOpenclaw(): string | null {
  try {
    const result = execSync('which openclaw', { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] }).trim();
    return result || null;
  } catch {
    return null;
  }
}

function run(args: string[]): string | null {
  const bin = findOpenclaw();
  if (!bin) return null;
  try {
    return execSync(`${bin} ${args.join(' ')}`, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] }).trim();
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error(`[gateway] openclaw ${args[0]} failed: ${msg}`);
    return null;
  }
}

export function createCronJob(agentId: string, prompt: string, schedule = '*/5 * * * *'): boolean {
  const result = run(['cron', 'add', '--agent', agentId, '--schedule', JSON.stringify(schedule), '--prompt', JSON.stringify(prompt)]);
  if (result === null) {
    console.error(`[gateway] Could not create cron job for ${agentId} (openclaw not found or command failed)`);
    return false;
  }
  return true;
}

export function removeCronJobs(prefix: string): boolean {
  const result = run(['cron', 'list', '--json']);
  if (!result) return false;
  try {
    const jobs = JSON.parse(result) as Array<{ id: string; agent: string }>;
    for (const job of jobs) {
      if (job.agent.startsWith(prefix)) {
        run(['cron', 'remove', job.id]);
      }
    }
    return true;
  } catch {
    return false;
  }
}

export function triggerAgent(agentId: string, prompt: string): boolean {
  const result = run(['session', 'start', '--agent', agentId, '--prompt', JSON.stringify(prompt)]);
  if (result === null) {
    console.error(`[gateway] Could not trigger ${agentId}`);
    return false;
  }
  return true;
}
