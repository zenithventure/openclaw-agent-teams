import { readFileSync, existsSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname } from 'node:path';

const pidDir = join(homedir(), '.openclaw', 'legacy-mod');
const pidFile = join(pidDir, 'dashboard.pid');
const __dirname = dirname(fileURLToPath(import.meta.url));
const daemonScript = join(__dirname, 'daemon.js');

function readPid(): number | null {
  if (!existsSync(pidFile)) return null;
  const pid = parseInt(readFileSync(pidFile, 'utf-8').trim(), 10);
  if (isNaN(pid)) return null;
  try {
    process.kill(pid, 0); // signal 0 = liveness check
    return pid;
  } catch {
    rmSync(pidFile, { force: true });
    return null;
  }
}

export function startDashboard(port = 3334): void {
  const existing = readPid();
  if (existing) {
    console.log(`Dashboard already running (PID ${existing})`);
    return;
  }

  const child = spawn('node', [daemonScript, String(port)], {
    detached: true,
    stdio: 'ignore',
  });
  child.unref();
  console.log(`Dashboard started at http://localhost:${port}`);
}

export function stopDashboard(): void {
  const pid = readPid();
  if (!pid) {
    console.log('Dashboard is not running.');
    return;
  }
  try {
    process.kill(pid, 'SIGTERM');
    rmSync(pidFile, { force: true });
    console.log(`Dashboard stopped (PID ${pid}).`);
  } catch {
    console.log('Could not stop dashboard process.');
  }
}

export function dashboardStatus(): void {
  const pid = readPid();
  if (pid) {
    console.log(`Dashboard running (PID ${pid})`);
  } else {
    console.log('Dashboard is not running.');
  }
}
