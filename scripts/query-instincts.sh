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
  # 쿼리 명령
  top-failures|hot-files|pass-rate|weekly-trend|failure-trend|recent-errors|summary|today|health)
    node "$STORE_JS" query "$CMD" "$@"
    ;;
  # 관리 명령
  cleanup)
    node "$STORE_JS" cleanup "$@"
    ;;
  aggregate)
    node "$STORE_JS" aggregate "$@"
    ;;
  export)
    node "$STORE_JS" export "$@"
    ;;
  migrate)
    node "$STORE_JS" migrate
    ;;
  help|--help|-h)
    cat <<EOF
Usage: query-instincts.sh <command> [args]

Queries:
  summary                        전체 통계 요약
  today                          오늘 통과율 (total/all_pass/ts_fail/test_fail)
  health                         DB 상태 (행 수, 날짜 범위, 스키마 버전)
  top-failures [days=7]          최근 N일 실패 많은 파일 TOP 10
  hot-files [days=30]            최근 N일 자주 수정된 파일 TOP 10
  pass-rate [days=30]            일별 통과율
  weekly-trend [weeks=4]         주간 트렌드 (통과율 %)
  failure-trend [days=14]        일별 실패 추이 (ts/test/eslint)
  recent-errors [n=20]           최근 도구 실패 N건

Management:
  cleanup [--max-age-days 90] [--max-rows 50000]   오래된 데이터 정리 + vacuum
  aggregate [date]               지정 날짜 daily_summary 재계산 (기본: 오늘)
  export [--format json|csv] [--since YYYY-MM-DD]  데이터 내보내기
  migrate                        스키마 마이그레이션 적용

출력 형식: JSON. 파이프로 jq와 조합 가능:
  query-instincts.sh top-failures 14 | jq '.[] | "\(.file): TS=\(.typecheck_fails)"'
  query-instincts.sh weekly-trend 8 | jq '.[] | "\(.week): \(.pass_pct)%"'
  query-instincts.sh export --format csv --since 2026-04-01 > metrics.csv
EOF
    ;;
  *)
    echo "Unknown command: $CMD" >&2
    echo "Run 'query-instincts.sh help' for usage" >&2
    exit 1
    ;;
esac
