#!/usr/bin/env bash
# PreToolUse hook: do not let Claude change a test that existed before this branch.
# A fix must pass the old tests, not rewrite them. Claude can still add new test files.
# Exit code 2 blocks the edit. Claude reads stderr.
# Exit code 0 allows the edit.

# Files that count as tests (extended regex on the path from the repo root). Change it to match your project.
TEST_PATTERN="${TEST_PATTERN:-(^|/)(tests?|__tests__)/|\.(test|spec)\.[cm]?[jt]sx?$|(^|/)test_[^/]*\.py$|_test\.(py|go)$}"

# If SPEC.md says the old behavior was wrong, a person starts Claude with ALLOW_TEST_EDITS=1.
[ "${ALLOW_TEST_EDITS:-0}" = "1" ] && exit 0

file=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
[ -z "$file" ] && exit 0

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
rel="${file#"$root"/}"

printf '%s\n' "$rel" | grep -Eq "$TEST_PATTERN" || exit 0

# The branch that holds the tests to protect. Default: the remote's default branch.
base="${BASE_REF:-}"
if [ -z "$base" ]; then
  for ref in origin/HEAD origin/main main; do
    if git rev-parse --verify -q "$ref^{commit}" >/dev/null; then
      base="$ref"
      break
    fi
  done
fi
[ -z "$base" ] && exit 0

# A new test file is allowed. A test file that exists on the base branch is blocked.
if git cat-file -e "$base:$rel" 2>/dev/null; then
  {
    echo "Blocked: $rel is a test that existed before this branch ($base)."
    echo "Do not change old tests to make them pass. Fix the code instead."
    echo "Put new tests in a new test file."
    echo "If SPEC.md says the old behavior was wrong, stop and ask a person."
  } >&2
  exit 2
fi

exit 0
