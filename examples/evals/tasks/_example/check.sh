#!/usr/bin/env bash
# Exit 0 if Claude's result is correct. This script runs inside the task's worktree.
# A good check runs the tests from the real merged change. Claude did not see those tests.
set -e

# The commit of the real merged change.
ACCEPTED="REPLACE-WITH-THE-MERGED-COMMIT"

git checkout "$ACCEPTED" -- tests/settings/display-name.test.ts
npm test -- tests/settings/display-name.test.ts
