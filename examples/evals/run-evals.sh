#!/usr/bin/env bash
# Run each eval task with your current CLAUDE.md, REVIEW.md, and .claude/ folder.
# Run it after you change CLAUDE.md, a skill, a hook, or a subagent. Compare the pass count with the last run.
#
# Each task is a folder in evals/tasks/ with three files:
#   base       the commit to start from: the commit before the real change
#   prompt.md  the request, as a person gave it
#   check.sh   exits 0 if the result is correct. It runs inside the task's worktree.
# A task folder can also hold files for check.sh, such as a hidden test.
# The script skips folders whose names start with "_".
#
# Do not create branches in this repo while the script runs. It deletes every branch that appears during a task.
#
# Usage: evals/run-evals.sh [task-name ...]

# A command to run in each worktree before Claude starts. Example: SETUP_CMD="npm ci"
SETUP_CMD="${SETUP_CMD:-}"

# Added before each prompt. Without it, a "spec first" rule in CLAUDE.md can make Claude stop and ask a question.
EVAL_NOTE="${EVAL_NOTE:-This is an eval task. No change folder (INTENT.md, SPEC.md, PLAN.md) is needed. Work on the current detached HEAD. Do not create a branch, commit, push, or open a pull request.}"

# The Claude Code command. Change it only to test this script.
CLAUDE_BIN="${CLAUDE_BIN:-claude}"

root=$(git rev-parse --show-toplevel) || exit 1
tasks_dir="$root/evals/tasks"
results_dir="$root/evals/results/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$results_dir" || exit 1

branches() { git -C "$root" for-each-ref --format='%(refname:short)' refs/heads | sort; }

names=("$@")
if [ "$#" -eq 0 ]; then
  for dir in "$tasks_dir"/*/; do
    name=$(basename "$dir")
    case "$name" in _* | '*') continue ;; esac
    names+=("$name")
  done
fi

pass=0
total=0
for name in "${names[@]}"; do
  task="$tasks_dir/$name"
  if [ ! -f "$task/base" ] || [ ! -f "$task/prompt.md" ] || [ ! -f "$task/check.sh" ]; then
    echo "SKIP $name: needs base, prompt.md, and check.sh"
    continue
  fi
  total=$((total + 1))
  log="$results_dir/$name.log"

  # The worktree is outside the repo, so Claude does not load the repo's own CLAUDE.md from a parent folder.
  wt=$(mktemp -d)
  if ! git -C "$root" worktree add --detach --quiet "$wt" "$(tr -d '[:space:]' < "$task/base")" >"$log" 2>&1; then
    echo "FAIL $name: cannot create a worktree at the base commit (log: $log)"
    rm -rf "$wt"
    continue
  fi

  # Test your current setup, not the setup from the old commit.
  if [ -d "$root/.claude" ]; then
    rm -rf "$wt/.claude"
    cp -R "$root/.claude" "$wt/.claude"
  fi
  for f in CLAUDE.md REVIEW.md; do
    [ -f "$root/$f" ] && cp "$root/$f" "$wt/$f"
  done
  # Add your current ignore lines too. Otherwise check output, such as screenshots, is not ignored
  # at the old commit, and the Stop hook sees a change and runs the checks again at every stop.
  [ -f "$root/.gitignore" ] && cat "$root/.gitignore" >>"$wt/.gitignore"

  # Commit the copied setup files in the worktree, so git is clean when Claude starts.
  git -C "$wt" add -A >/dev/null 2>&1
  git -C "$wt" -c user.name=eval -c user.email=eval@localhost commit -q -m "eval: current setup" >/dev/null 2>&1

  before=$(branches)
  (
    cd "$wt" || exit 1
    if [ -n "$SETUP_CMD" ]; then
      bash -c "$SETUP_CMD" || exit 1
    fi
    "$CLAUDE_BIN" -p "$EVAL_NOTE

$(cat "$task/prompt.md")" --permission-mode auto
  ) >>"$log" 2>&1

  if (cd "$wt" && bash "$task/check.sh") >>"$log" 2>&1; then
    pass=$((pass + 1))
    echo "PASS $name"
  else
    echo "FAIL $name (log: $log)"
  fi

  git -C "$root" worktree remove --force "$wt" >/dev/null 2>&1 || rm -rf "$wt"
  git -C "$root" worktree prune

  # Delete the branches that appeared during this task.
  for b in $(comm -13 <(printf '%s\n' "$before") <(branches)); do
    git -C "$root" branch -D "$b" >/dev/null 2>&1 && echo "Deleted branch $b, created during the task." >>"$log"
  done
done

echo "$pass of $total tasks passed" | tee "$results_dir/summary.txt"
