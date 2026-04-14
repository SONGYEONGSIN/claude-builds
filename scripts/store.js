#!/usr/bin/env node
// store.js — Claude Forge instinct store (SQLite via better-sqlite3)
//
// Usage:
//   node store.js init
//   echo '<json>' | node store.js append-event
//   echo '<json>' | node store.js append-failure
//   node store.js query <query-name> [args...]
//
// Environment:
//   CLAUDE_PROJECT_ROOT — override project root (default: git rev-parse --show-toplevel)

const path = require('path');
const { execSync } = require('child_process');

function projectRoot() {
  if (process.env.CLAUDE_PROJECT_ROOT) return process.env.CLAUDE_PROJECT_ROOT;
  try {
    return execSync('git rev-parse --show-toplevel', { encoding: 'utf8' }).trim();
  } catch {
    return process.cwd();
  }
}

const DB_PATH = path.join(projectRoot(), '.claude', 'store.db');

let Database;
try {
  Database = require('better-sqlite3');
} catch {
  console.error('better-sqlite3 not installed. Run: cd .claude/scripts && npm install');
  process.exit(2);
}

function openDb() {
  const db = new Database(DB_PATH);
  db.pragma('journal_mode = WAL');
  db.exec(`
    CREATE TABLE IF NOT EXISTS events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      timestamp TEXT NOT NULL,
      date TEXT NOT NULL,
      event_type TEXT NOT NULL,
      tool TEXT,
      file TEXT,
      prettier_result TEXT,
      eslint_result TEXT,
      typecheck_result TEXT,
      test_result TEXT,
      error_message TEXT,
      raw_json TEXT
    );
    CREATE INDEX IF NOT EXISTS idx_events_date ON events(date);
    CREATE INDEX IF NOT EXISTS idx_events_file ON events(file);
    CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);
  `);
  return db;
}

function readStdin() {
  return new Promise((resolve) => {
    let data = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', (c) => { data += c; });
    process.stdin.on('end', () => resolve(data.trim()));
  });
}

async function appendEvent() {
  const raw = await readStdin();
  if (!raw) return;
  const e = JSON.parse(raw);
  const date = (e.timestamp || '').substring(0, 10);
  const db = openDb();
  db.prepare(
    `INSERT INTO events (timestamp, date, event_type, tool, file,
      prettier_result, eslint_result, typecheck_result, test_result, raw_json)
     VALUES (?, ?, 'tool_result', ?, ?, ?, ?, ?, ?, ?)`
  ).run(
    e.timestamp, date, e.tool || null, e.file || null,
    e.results?.prettier || null, e.results?.eslint || null,
    e.results?.typecheck || null, e.results?.test || null, raw
  );
  db.close();
}

async function appendFailure() {
  const raw = await readStdin();
  if (!raw) return;
  const e = JSON.parse(raw);
  const date = (e.timestamp || '').substring(0, 10);
  const db = openDb();
  db.prepare(
    `INSERT INTO events (timestamp, date, event_type, tool, error_message, raw_json)
     VALUES (?, ?, 'tool_failure', ?, ?, ?)`
  ).run(e.timestamp, date, e.tool || null, e.error || null, raw);
  db.close();
}

const QUERIES = {
  'top-failures': (days = 7) => ({
    sql: `
      SELECT file,
             SUM(CASE WHEN typecheck_result='fail' THEN 1 ELSE 0 END) AS typecheck_fails,
             SUM(CASE WHEN test_result='fail' THEN 1 ELSE 0 END) AS test_fails,
             SUM(CASE WHEN eslint_result='fail' THEN 1 ELSE 0 END) AS eslint_fails,
             COUNT(*) AS total_events
      FROM events
      WHERE date >= date('now', ?) AND file IS NOT NULL AND event_type='tool_result'
      GROUP BY file
      HAVING typecheck_fails + test_fails + eslint_fails > 0
      ORDER BY typecheck_fails + test_fails + eslint_fails DESC
      LIMIT 10
    `,
    params: [`-${Number(days)} days`],
  }),
  'hot-files': (days = 30) => ({
    sql: `
      SELECT file, COUNT(*) AS modifications
      FROM events
      WHERE date >= date('now', ?) AND event_type='tool_result' AND file IS NOT NULL
      GROUP BY file
      ORDER BY modifications DESC
      LIMIT 10
    `,
    params: [`-${Number(days)} days`],
  }),
  'pass-rate': (days = 30) => ({
    sql: `
      SELECT date,
             COUNT(*) AS total,
             SUM(CASE WHEN prettier_result='pass' AND eslint_result='pass'
                      AND typecheck_result='pass' AND test_result='pass'
                 THEN 1 ELSE 0 END) AS all_pass
      FROM events
      WHERE date >= date('now', ?) AND event_type='tool_result'
      GROUP BY date
      ORDER BY date DESC
    `,
    params: [`-${Number(days)} days`],
  }),
  'recent-errors': (n = 20) => ({
    sql: `
      SELECT timestamp, tool, error_message
      FROM events
      WHERE event_type='tool_failure'
      ORDER BY timestamp DESC
      LIMIT ?
    `,
    params: [Number(n)],
  }),
  summary: () => ({
    sql: `
      SELECT
        COUNT(*) AS total_events,
        SUM(CASE WHEN event_type='tool_failure' THEN 1 ELSE 0 END) AS failures,
        SUM(CASE WHEN event_type='tool_result' AND prettier_result='pass'
                 AND eslint_result='pass' AND typecheck_result='pass' AND test_result='pass'
                 THEN 1 ELSE 0 END) AS all_pass,
        COUNT(DISTINCT file) AS unique_files,
        COUNT(DISTINCT date) AS days_active,
        MIN(date) AS first_date,
        MAX(date) AS last_date
      FROM events
    `,
    params: [],
  }),
  today: () => ({
    sql: `
      SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN prettier_result='pass' AND eslint_result='pass'
                 AND typecheck_result='pass' AND test_result='pass'
            THEN 1 ELSE 0 END) AS all_pass,
        SUM(CASE WHEN typecheck_result='fail' THEN 1 ELSE 0 END) AS ts_fail,
        SUM(CASE WHEN test_result='fail' THEN 1 ELSE 0 END) AS test_fail
      FROM events
      WHERE date = date('now') AND event_type='tool_result'
    `,
    params: [],
  }),
};

function runQuery(name, ...args) {
  const q = QUERIES[name];
  if (!q) {
    console.error(`Unknown query: ${name}. Available: ${Object.keys(QUERIES).join(', ')}`);
    process.exit(1);
  }
  const { sql, params } = q(...args);
  const db = openDb();
  const rows = db.prepare(sql).all(...params);
  db.close();
  console.log(JSON.stringify(rows, null, 2));
}

(async () => {
  const [cmd, ...args] = process.argv.slice(2);
  try {
    switch (cmd) {
      case 'init':
        openDb().close();
        console.log('ok');
        break;
      case 'append-event':
        await appendEvent();
        break;
      case 'append-failure':
        await appendFailure();
        break;
      case 'query':
        runQuery(args[0], ...args.slice(1));
        break;
      default:
        console.error('Usage: node store.js <init|append-event|append-failure|query> [args]');
        process.exit(1);
    }
  } catch (e) {
    console.error(`store.js error: ${e.message}`);
    process.exit(1);
  }
})();
