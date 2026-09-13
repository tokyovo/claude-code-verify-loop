#!/usr/bin/env bash
# Stop hook: do not let Claude finish while the checks fail.
# Exit code 2 blocks the stop. Claude reads stderr and keeps working.
# Exit code 0 lets Claude finish.

# The command that must pass. Change it to match your project.
VERIFY_CMD="${VERIFY_CMD:-npm run lint && npm run typecheck && npm test}"

# Stop blocking after this many failed attempts in a row, so the loop cannot run forever.
MAX_BLOCKS="${MAX_BLOCKS:-5}"

input=$(cat)
session=$(printf '%s' "$input" | jq -r '.session_id // "default"')
counter="${TMPDIR:-/tmp}/claude-stop-verify-${session}"

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

# Skip when nothing changed in git: there is nothing new to verify.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && [ -z "$(git status --porcelain)" ]; then
  rm -f "$counter"
  exit 0
fi

if output=$(bash -c "$VERIFY_CMD" 2>&1); then
  rm -f "$counter"
  exit 0
fi

count=$(( $(cat "$counter" 2>/dev/null || echo 0) + 1 ))
echo "$count" > "$counter"

if [ "$count" -gt "$MAX_BLOCKS" ]; then
  rm -f "$counter"
  echo "Checks still fail after $MAX_BLOCKS attempts. Stopping so a human can look." >&2
  exit 0
fi

{
  echo "Checks failed (attempt $count of $MAX_BLOCKS). Do not stop yet."
  echo "Command: $VERIFY_CMD"
  echo "Last 40 lines of output:"
  printf '%s\n' "$output" | tail -n 40
  echo "Fix the cause, run the command again, and show the passing output."
} >&2
exit 2
