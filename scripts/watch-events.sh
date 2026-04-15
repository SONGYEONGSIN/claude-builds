#!/bin/bash
# watch-events.sh — 에이전트 실시간 관측 스트림 (observability)
# 사용법:
#   watch-events.sh                     — 전체 이벤트 실시간 스트림
#   watch-events.sh --errors-only       — 실패/에러만
#   watch-events.sh --file Button       — 파일명 substring 필터
#   watch-events.sh --raw               — 원본 JSON 라인 (파이프용)

set -u

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [ -z "$PROJECT_ROOT" ]; then
  echo "ERROR: git 프로젝트 내에서 실행하세요" >&2
  exit 1
fi

EVENTS_FILE="${PROJECT_ROOT}/.claude/events.jsonl"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

ERRORS_ONLY=0
FILE_PATTERN=""
RAW=0

while [ $# -gt 0 ]; do
  case "$1" in
    --errors-only|-e) ERRORS_ONLY=1; shift ;;
    --file)
      [ $# -lt 2 ] && { echo "--file은 패턴 인자 필요" >&2; exit 1; }
      FILE_PATTERN="$2"; shift 2 ;;
    --raw|-r) RAW=1; shift ;;
    --help|-h|help)
      cat <<EOF
Usage: watch-events.sh [옵션]

옵션:
  --errors-only, -e         실패/에러 이벤트만 표시 (status != all_pass 또는 type == tool_failure)
  --file <pattern>          파일 경로 substring으로 필터
  --raw, -r                 원본 JSONL 출력 (jq/grep 파이프용)
  --help, -h                도움말

예시:
  watch-events.sh                           # 전체 스트림 컬러 포맷
  watch-events.sh --errors-only             # 실패만
  watch-events.sh --file src/components     # components 하위만
  watch-events.sh --raw | jq '.file'        # 파일명 추출

이벤트 파일: $EVENTS_FILE
EOF
      exit 0 ;;
    *)
      echo "Unknown option: $1 (see --help)" >&2
      exit 1 ;;
  esac
done

# 이벤트 파일 미존재 시 생성 (touch)
if [ ! -f "$EVENTS_FILE" ]; then
  echo "Events file not yet created: $EVENTS_FILE"
  echo "  아직 훅이 실행된 적 없습니다. 파일 편집 후 재시도하거나 아래 명령으로 대기:"
  touch "$EVENTS_FILE" 2>/dev/null || { echo "  (파일 생성 실패 — .claude/ 디렉토리 확인)"; exit 1; }
  echo "  (빈 파일 생성 완료, 새 이벤트 대기 중...)"
fi

# jq 필터 구축
JQ_FILTER='.'
if [ "$ERRORS_ONLY" = 1 ]; then
  JQ_FILTER="${JQ_FILTER} | select(.status != \"all_pass\" or .type == \"tool_failure\")"
fi
if [ -n "$FILE_PATTERN" ]; then
  JQ_FILTER="${JQ_FILTER} | select((.file // \"\") | contains(\"${FILE_PATTERN}\"))"
fi

command -v jq &>/dev/null || { echo "ERROR: jq 미설치" >&2; exit 1; }

# 출력 경로 분기
if [ "$RAW" = 1 ]; then
  tail -n 0 -f "$EVENTS_FILE" | jq -c --unbuffered "$JQ_FILTER"
else
  FORMATTER="${SCRIPT_DIR}/events-tail.js"
  if [ -f "$FORMATTER" ] && command -v node &>/dev/null; then
    tail -n 0 -f "$EVENTS_FILE" | jq -c --unbuffered "$JQ_FILTER" | node "$FORMATTER"
  else
    # 포맷터 없으면 raw 폴백
    tail -n 0 -f "$EVENTS_FILE" | jq -c --unbuffered "$JQ_FILTER"
  fi
fi
