import { DatabaseSync } from 'node:sqlite';
import { existsSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { homedir } from 'node:os';

const DB_PATH = join(homedir(), '.openclaw', 'legacy-mod.db');
let db: DatabaseSync | null = null;

export function getDbPath(): string {
  return DB_PATH;
}

interface Migration {
  version: number;
  description: string;
  up: (db: DatabaseSync) => void;
}

const migrations: Migration[] = [
  {
    version: 1,
    description: 'Baseline schema stamp',
    up: () => { /* no-op: stamps existing schema as version 1 */ },
  },
];

function initSchemaVersion(db: DatabaseSync): void {
  db.exec(`
    CREATE TABLE IF NOT EXISTS schema_version (
      version     INTEGER PRIMARY KEY,
      applied_at  TEXT DEFAULT (datetime('now')),
      description TEXT
    )
  `);
}

function runMigrations(db: DatabaseSync): void {
  initSchemaVersion(db);
  const row = db.prepare('SELECT MAX(version) as v FROM schema_version').get() as { v: number | null } | undefined;
  const current = row?.v ?? 0;
  for (const m of migrations) {
    if (m.version <= current) continue;
    db.exec('BEGIN');
    try {
      m.up(db);
      db.prepare('INSERT INTO schema_version (version, description) VALUES (?, ?)').run(m.version, m.description);
      db.exec('COMMIT');
    } catch (e) {
      db.exec('ROLLBACK');
      throw e;
    }
  }
}

export function getSchemaVersion(): number {
  const d = getDb();
  const row = d.prepare('SELECT MAX(version) as v FROM schema_version').get() as { v: number | null } | undefined;
  return row?.v ?? 0;
}

export function getLatestSchemaVersion(): number {
  return migrations.length > 0 ? migrations[migrations.length - 1].version : 0;
}

export function getDb(): DatabaseSync {
  if (db) return db;
  const dir = dirname(DB_PATH);
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
  db = new DatabaseSync(DB_PATH);
  db.exec('PRAGMA journal_mode = WAL');
  initSchema(db);
  runMigrations(db);
  return db;
}

function initSchema(db: DatabaseSync): void {
  db.exec(`
    CREATE TABLE IF NOT EXISTS runs (
      id          TEXT PRIMARY KEY,
      task        TEXT NOT NULL,
      status      TEXT NOT NULL DEFAULT 'running',
      context     TEXT NOT NULL DEFAULT '{}',
      created_at  TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at  TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS steps (
      id              TEXT PRIMARY KEY,
      run_id          TEXT NOT NULL REFERENCES runs(id),
      step_id         TEXT NOT NULL,
      step_name       TEXT NOT NULL,
      agent_id        TEXT NOT NULL,
      step_index      INTEGER NOT NULL,
      input_template  TEXT NOT NULL,
      expects         TEXT,
      status          TEXT NOT NULL DEFAULT 'waiting',
      output          TEXT,
      retry_count     INTEGER NOT NULL DEFAULT 0,
      max_retries     INTEGER NOT NULL DEFAULT 2,
      type            TEXT NOT NULL DEFAULT 'single',
      loop_config     TEXT,
      current_module_id TEXT,
      started_at      TEXT,
      completed_at    TEXT,
      created_at      TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS modules (
      id              TEXT PRIMARY KEY,
      run_id          TEXT NOT NULL REFERENCES runs(id),
      module_index    INTEGER NOT NULL,
      module_id       TEXT NOT NULL,
      title           TEXT NOT NULL,
      description     TEXT,
      risk            TEXT,
      compliance_items TEXT,
      rollback        TEXT,
      status          TEXT NOT NULL DEFAULT 'pending',
      output          TEXT,
      retry_count     INTEGER NOT NULL DEFAULT 0,
      max_retries     INTEGER NOT NULL DEFAULT 2,
      created_at      TEXT NOT NULL DEFAULT (datetime('now')),
      completed_at    TEXT
    );

    CREATE TABLE IF NOT EXISTS events (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      run_id      TEXT NOT NULL REFERENCES runs(id),
      event_type  TEXT NOT NULL,
      step_id     TEXT,
      module_id   TEXT,
      data        TEXT,
      created_at  TEXT NOT NULL DEFAULT (datetime('now'))
    );
  `);
}

export function emitEvent(runId: string, eventType: string, stepId?: string, moduleId?: string, data?: Record<string, unknown>): void {
  const db = getDb();
  db.prepare(
    'INSERT INTO events (run_id, event_type, step_id, module_id, data) VALUES (?, ?, ?, ?, ?)'
  ).run(runId, eventType, stepId ?? null, moduleId ?? null, data ? JSON.stringify(data) : null);
}

export interface RunRow {
  id: string; task: string; status: string; context: string;
  created_at: string; updated_at: string;
}

export interface StepRow {
  id: string; run_id: string; step_id: string; step_name: string; agent_id: string;
  step_index: number; input_template: string; expects: string | null; status: string;
  output: string | null; retry_count: number; max_retries: number; type: string;
  loop_config: string | null; current_module_id: string | null;
  started_at: string | null; completed_at: string | null; created_at: string;
}

export interface ModuleRow {
  id: string; run_id: string; module_index: number; module_id: string; title: string;
  description: string | null; risk: string | null; compliance_items: string | null;
  rollback: string | null; status: string; output: string | null;
  retry_count: number; max_retries: number; created_at: string; completed_at: string | null;
}

export interface EventRow {
  id: number; run_id: string; event_type: string; step_id: string | null;
  module_id: string | null; data: string | null; created_at: string;
}

export function getActiveRun(): RunRow | undefined {
  const db = getDb();
  return db.prepare(
    "SELECT * FROM runs WHERE status IN ('running','blocked','paused') ORDER BY created_at DESC LIMIT 1"
  ).get() as RunRow | undefined;
}

export function getRun(runId: string): RunRow | undefined {
  const db = getDb();
  return db.prepare('SELECT * FROM runs WHERE id = ?').get(runId) as RunRow | undefined;
}

export function getAllRuns(): RunRow[] {
  const db = getDb();
  return db.prepare('SELECT * FROM runs ORDER BY created_at DESC').all() as unknown as RunRow[];
}

export function getSteps(runId: string): StepRow[] {
  const db = getDb();
  return db.prepare('SELECT * FROM steps WHERE run_id = ? ORDER BY step_index').all(runId) as unknown as StepRow[];
}

export function getStep(stepId: string): StepRow | undefined {
  const db = getDb();
  return db.prepare('SELECT * FROM steps WHERE id = ?').get(stepId) as StepRow | undefined;
}

export function getModules(runId: string): ModuleRow[] {
  const db = getDb();
  return db.prepare('SELECT * FROM modules WHERE run_id = ? ORDER BY module_index').all(runId) as unknown as ModuleRow[];
}

export function getEvents(runId: string, limit = 50): EventRow[] {
  const db = getDb();
  return db.prepare('SELECT * FROM events WHERE run_id = ? ORDER BY created_at DESC LIMIT ?').all(runId, limit) as unknown as EventRow[];
}
