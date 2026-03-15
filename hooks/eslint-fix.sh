#!/bin/bash
# ESLint auto-fix hook - PostToolUse (Edit/Write)
INPUT=$(cat)
LOG_FILE="/tmp/eslint-hook.log"

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# .ts/.tsx/.js/.jsx 파일만
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx) ;;
  *) exit 0 ;;
esac

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ESLint: $FILE_PATH" >> "$LOG_FILE"

# 가장 가까운 eslint.config.* 위치에서 실행
DIR=$(dirname "$FILE_PATH")
while [ "$DIR" != "/" ]; do
  if ls "$DIR"/eslint.config.* 2>/dev/null | grep -q .; then
    break
  fi
  DIR=$(dirname "$DIR")
done

REL_PATH=$(python3 -c "import os; print(os.path.relpath('$FILE_PATH', '$DIR'))")
OUTPUT=$(cd "$DIR" && npx eslint --fix "$REL_PATH" 2>&1)
EXIT_CODE=$?

echo "$OUTPUT" >> "$LOG_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] eslint exit=$EXIT_CODE" >> "$LOG_FILE"

exit 0
