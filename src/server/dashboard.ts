import { createServer, type IncomingMessage, type ServerResponse } from 'node:http';
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { getActiveRun, getRun, getAllRuns, getSteps, getModules, getEvents, type StepRow } from '../db.js';
import { getStatusJson } from '../status.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

function json(res: ServerResponse, data: unknown, status = 200): void {
  res.writeHead(status, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
  });
  res.end(JSON.stringify(data));
}

function notFound(res: ServerResponse): void {
  json(res, { error: 'Not found' }, 404);
}

function serveIndex(res: ServerResponse): void {
  try {
    const html = readFileSync(join(__dirname, 'index.html'), 'utf-8');
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(html);
  } catch {
    res.writeHead(500, { 'Content-Type': 'text/plain' });
    res.end('index.html not found');
  }
}

function route(req: IncomingMessage, res: ServerResponse): void {
  const url = new URL(req.url ?? '/', `http://${req.headers.host ?? 'localhost'}`);
  const path = url.pathname;

  // Static
  if (path === '/' || path === '/index.html') {
    serveIndex(res);
    return;
  }

  // API
  if (path === '/api/status') {
    const status = getStatusJson();
    json(res, status ?? { status: 'no_run' });
    return;
  }

  if (path === '/api/runs') {
    const runs = getAllRuns();
    json(res, runs);
    return;
  }

  // /api/runs/:id patterns
  const runMatch = path.match(/^\/api\/runs\/([^/]+)$/);
  if (runMatch) {
    const run = getRun(runMatch[1]);
    if (!run) return notFound(res);
    const steps = getSteps(run.id);
    json(res, { ...run, steps });
    return;
  }

  const stepsMatch = path.match(/^\/api\/runs\/([^/]+)\/steps$/);
  if (stepsMatch) {
    const steps = getSteps(stepsMatch[1]);
    json(res, steps.map((s: StepRow) => {
      let durationSeconds: number | null = null;
      if (s.started_at && s.completed_at) {
        durationSeconds = Math.round(
          (new Date(s.completed_at + 'Z').getTime() - new Date(s.started_at + 'Z').getTime()) / 1000
        );
      }
      return {
        step_id: s.step_id,
        step_name: s.step_name,
        agent_id: s.agent_id,
        status: s.status,
        duration_seconds: durationSeconds,
        retry_count: s.retry_count,
        output_summary: s.output ? s.output.slice(0, 200) : null,
      };
    }));
    return;
  }

  const modulesMatch = path.match(/^\/api\/runs\/([^/]+)\/modules$/);
  if (modulesMatch) {
    const modules = getModules(modulesMatch[1]);
    json(res, modules.map(m => ({
      module_id: m.module_id,
      title: m.title,
      status: m.status,
      risk: m.risk,
      compliance_items: m.compliance_items ? JSON.parse(m.compliance_items) : [],
      retry_count: m.retry_count,
    })));
    return;
  }

  const eventsMatch = path.match(/^\/api\/runs\/([^/]+)\/events$/);
  if (eventsMatch) {
    const events = getEvents(eventsMatch[1], 100);
    json(res, events);
    return;
  }

  const complianceMatch = path.match(/^\/api\/runs\/([^/]+)\/compliance$/);
  if (complianceMatch) {
    const modules = getModules(complianceMatch[1]);
    const matrix: Record<string, string> = {};
    for (const m of modules) {
      if (m.compliance_items) {
        try {
          const items = JSON.parse(m.compliance_items) as string[];
          for (const item of items) {
            if (m.status === 'done') matrix[item] = 'pass';
            else if (m.status === 'failed') matrix[item] = 'fail';
            else if (!matrix[item]) matrix[item] = 'pending';
          }
        } catch { /* skip */ }
      }
    }
    json(res, matrix);
    return;
  }

  notFound(res);
}

export function createDashboardServer(port: number): ReturnType<typeof createServer> {
  const server = createServer(route);
  server.listen(port, () => {
    console.log(`Dashboard running at http://localhost:${port}`);
  });
  return server;
}
