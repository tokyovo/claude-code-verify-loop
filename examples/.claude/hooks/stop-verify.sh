#!/usr/bin/env bash
# Stop hook: do not let Claude finish while the checks fail.
# Exit code 2 blocks the stop. Claude reads stderr and keeps working.
# Exit code 0 lets Claude finish.
#
# The hook runs the checks only when the code changed since the checks last passed.
# It compares file contents, not commits, so a commit does not make it skip the checks or run them again.

# The command that must pass. Change it to match your project.
VERIFY_CMD="${VERIFY_CMD:-npm run lint && npm run typecheck && npm test}"

# Stop blocking after this many failed attempts in a row, so the loop cannot run forever.
MAX_BLOCKS="${MAX_BLOCKS:-5}"

# A change to these files alone does not need the checks (extended regex on the path from the repo root).
DOCS_PATTERN="${DOCS_PATTERN:-^changes/|\.md$}"

input=$(cat)
session=$(printf '%s' "$input" | jq -r '.session_id // "default"')
state="${TMPDIR:-/tmp}/claude-stop-verify-${session}"
counter="$state.count"
passed="$state.passed"

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

tree=""
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # A fingerprint of every file in the project, including files that are not committed.
  # It uses a temporary copy of the index, so the real index does not change.
  # Git stores the file contents as objects; its normal cleanup removes the unused ones.
  index=$(mktemp)
  cp "$(git rev-parse --git-path index)" "$index" 2>/dev/null
  if GIT_INDEX_FILE="$index" git add -A >/dev/null 2>&1; then
    tree=$(GIT_INDEX_FILE="$index" git write-tree 2>/dev/null)
  fi
  rm -f "$index"

  last=$(cat "$passed" 2>/dev/null)

  # Nothing changed since the checks last passed.
  if [ -n "$tree" ] && [ "$tree" = "$last" ]; then
    rm -f "$counter"
    exit 0
  fi

  # Find what changed: since the last pass, or since the base branch if nothing passed yet.
  since="$last"
  if [ -z "$since" ]; then
    for ref in origin/HEAD origin/main main; do
      if since=$(git merge-base HEAD "$ref" 2>/dev/null); then
        break
      fi
      since=""
    done
  fi

  if [ -n "$tree" ] && [ -n "$since" ]; then
    changed=$(git diff --name-only "$since" "$tree" 2>/dev/null)
    # No change, or only documents changed: no checks needed.
    if [ -z "$changed" ] || ! printf '%s\n' "$changed" | grep -Evq "$DOCS_PATTERN"; then
      echo "$tree" > "$passed"
      rm -f "$counter"
      exit 0
    fi
  fi
fi

if output=$(bash -c "$VERIFY_CMD" 2>&1); then
  [ -n "$tree" ] && echo "$tree" > "$passed"
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
