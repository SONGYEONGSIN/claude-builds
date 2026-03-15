#!/bin/bash
INPUT=$(cat)
echo "$(date): HOOK TRIGGERED" >> /tmp/prettier-hook.log
echo "INPUT: $INPUT" >> /tmp/prettier-hook.log

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
echo "FILE_PATH: $FILE_PATH" >> /tmp/prettier-hook.log

if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
  npx prettier --write "$FILE_PATH" >> /tmp/prettier-hook.log 2>&1 || true
  echo "PRETTIER DONE" >> /tmp/prettier-hook.log
else
  echo "SKIPPED: file not found or empty path" >> /tmp/prettier-hook.log
fi
