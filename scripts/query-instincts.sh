#!/bin/bash
# query-instincts.sh — Instinct store 사전 정의 쿼리 CLI
# 사용법: query-instincts.sh <command> [args]

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STORE_JS="${SCRIPT_DIR}/store.js"

if [ ! -f "$STORE_JS" ]; then
  echo "ERROR: store.js not found at $STORE_JS" >&2
  exit 1
fi

CMD="${1:-summary}"
shift || true

case "$CMD" in
  top-failures|hot-files|pass-rate|recent-errors|summary|today)
    node "$STORE_JS" query "$CMD" "$@"
    ;;
  help|--help|-h)
    cat <<EOF
Usage: query-instincts.sh <command> [args]

Commands:
  summary                        전체 통계 요약
  today                          오늘 통과율 (total/all_pass/ts_fail/test_fail)
  top-failures [days=7]          최근 N일 실패 많은 파일 TOP 10
  hot-files [days=30]            최근 N일 자주 수정된 파일 TOP 10
  pass-rate [days=30]            일별 통과율
  recent-errors [n=20]           최근 도구 실패 N건

출력 형식: JSON. 파이프로 jq와 조합 가능:
  query-instincts.sh top-failures 14 | jq '.[] | "\(.file): TS=\(.typecheck_fails)"'
EOF
    ;;
  *)
    echo "Unknown command: $CMD" >&2
    echo "Run 'query-instincts.sh help' for usage" >&2
    exit 1
    ;;
esac
