import { writeFileSync, mkdirSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { homedir } from 'node:os';
import { createDashboardServer } from './dashboard.js';

const pidDir = join(homedir(), '.openclaw', 'legacy-mod');
const pidFile = join(pidDir, 'dashboard.pid');
const port = parseInt(process.argv[2] ?? '3334', 10);

mkdirSync(pidDir, { recursive: true });
writeFileSync(pidFile, String(process.pid));

const server = createDashboardServer(port);

function shutdown(): void {
  console.log('Shutting down dashboard...');
  server.close();
  try { rmSync(pidFile); } catch { /* ignore */ }
  process.exit(0);
}

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
