#!/bin/bash
set -u
# PostToolUseFailure hook: 도구 실행 실패 시 자동 복구/로깅
# Bash 명령 실패를 감지하여 에러 패턴을 기록하고 복구 힌트를 제공한다.

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
ERROR=$(echo "$INPUT" | jq -r '.error // empty' 2>/dev/null)

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
[ -z "$PROJECT_ROOT" ] && exit 0

METRICS_DIR="${PROJECT_ROOT}/.claude/metrics"
mkdir -p "$METRICS_DIR" 2>/dev/null || true

# 에러를 일별 메트릭에 기록
DATE=$(date +%Y-%m-%d)
METRICS_FILE="${METRICS_DIR}/daily-${DATE}.json"

EVENT=$(jq -n \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg tool "$TOOL_NAME" \
  --arg error "$ERROR" \
  '{timestamp: $ts, type: "tool_failure", tool: $tool, error: $error}')

if [ -f "$METRICS_FILE" ]; then
  jq --argjson evt "$EVENT" '.events += [$evt]' "$METRICS_FILE" > "${METRICS_FILE}.tmp" && mv "${METRICS_FILE}.tmp" "$METRICS_FILE"
else
  echo "{\"date\": \"${DATE}\", \"events\": [${EVENT}]}" > "$METRICS_FILE"
fi

# 복구 힌트 제공
HINT=""
case "$ERROR" in
  *"ENOENT"*|*"No such file"*)
    HINT="파일 경로를 확인하세요. 존재하지 않는 파일일 수 있습니다." ;;
  *"EACCES"*|*"Permission denied"*)
    HINT="파일 권한 문제입니다. chmod로 권한을 확인하세요." ;;
  *"tsc"*|*"TypeScript"*)
    HINT="TypeScript 타입 에러입니다. 타입 정의를 확인하세요." ;;
  *"ECONNREFUSED"*|*"ETIMEDOUT"*)
    HINT="네트워크 연결 실패입니다. 서버 상태를 확인하세요." ;;
esac

if [ -n "$HINT" ]; then
  echo "{\"additionalContext\": \"[tool-failure] ${HINT}\"}"
fi

exit 0
