#!/usr/bin/env node
// events-tail.js — events.jsonl 스트림을 사람 친화 컬러 라인으로 포맷
// stdin으로 JSON 라인 받아서 stdout으로 포맷된 텍스트 출력.
// watch-events.sh가 파이프 타겟으로 호출.

const readline = require('readline');

const RESET = '\x1b[0m';
const RED = '\x1b[31m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const CYAN = '\x1b[36m';
const MAGENTA = '\x1b[35m';
const GRAY = '\x1b[90m';
const BOLD = '\x1b[1m';

function mark(letter, result) {
  if (result === 'pass') return `${GREEN}${letter}${RESET}`;
  if (result === 'fail') return `${RED}${letter}${RESET}`;
  return `${GRAY}·${RESET}`;
}

function timeOf(ts) {
  if (!ts) return '--:--:--';
  const t = ts.split('T')[1] || ts;
  return t.substring(0, 8);
}

const rl = readline.createInterface({ input: process.stdin });

rl.on('line', (line) => {
  const raw = line.trim();
  if (!raw) return;

  try {
    const e = JSON.parse(raw);
    const time = timeOf(e.ts || e.timestamp);

    if (e.type === 'tool_failure') {
      const err = (e.error || 'unknown error').replace(/\s+/g, ' ').substring(0, 100);
      console.log(`${GRAY}${time}${RESET} ${RED}${BOLD}✗ FAIL${RESET} ${MAGENTA}${e.tool || '?'}${RESET}  ${RED}${err}${RESET}`);
      return;
    }

    const r = e.results || {};
    const badges = mark('P', r.prettier) + mark('E', r.eslint) + mark('T', r.typecheck) + mark('X', r.test);
    const statusColor = e.status === 'all_pass' ? GREEN : e.status === 'fail' ? RED : YELLOW;
    const statusLabel = (e.status || 'unknown').padEnd(11);
    const toolLabel = (e.tool || '?').padEnd(5);
    const file = e.file || '';

    console.log(`${GRAY}${time}${RESET} ${statusColor}${statusLabel}${RESET}[${badges}] ${CYAN}${toolLabel}${RESET} ${file}`);
  } catch {
    // 파싱 실패 시 원본 그대로
    console.log(line);
  }
});

rl.on('close', () => process.exit(0));
