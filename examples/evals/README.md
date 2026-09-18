# Evals: test your setup

An eval is a real past task with a known correct result. You give the task to Claude, then check the result.

Your `CLAUDE.md`, skills, hooks, and subagents control how Claude works. A change to one of them can make Claude worse, and nobody notices. Run the evals after each change to them. Compare the pass count with the last run.

## Add a task

1. Pick a real change or a real bug. Over time, collect 20–50 of them. Include past bugs, so they stay fixed.
2. Copy `tasks/_example/` to `tasks/<name>/`.
3. In `base`, write the commit to start from: the commit before the change, or a commit that still has the bug.
4. In `prompt.md`, write the request as a person gave it.
5. In `check.sh`, write a check that exits 0 when the result is correct. Choose one of two patterns:
   - **Tests from the merged change.** If your team already merged the change, `check.sh` checks out the tests from that commit and runs them. `_example/check.sh` shows this pattern.
   - **A hidden test next to `check.sh`.** If there is no merged change, write a test file in the task folder, for example `tasks/<name>/hidden.test.ts`. `check.sh` copies it into the worktree and runs it:

     ```bash
     here=$(cd "$(dirname "$0")" && pwd)
     cp "$here/hidden.test.ts" tests/zz-eval-<name>.test.ts
     npx vitest run tests/zz-eval-<name>.test.ts
     npm test
     ```

Before you trust a task, run its check on the `base` commit. The check must fail there.

## Keep tasks out of the way

- **Keep the task files out of test discovery and lint.** Many test tools find every `*.test.ts` file in the repo. A hidden test in `evals/` then runs in `npm test`, fails on its imports, and makes the Stop hook block every session. Limit the test tool to your test folder, or add `evals/` to its ignore list.
- **Claude can read files in the repo.** A hidden test in `evals/` is hidden from the eval run, because the worktree starts at the `base` commit. It is not hidden from your normal sessions. If that matters, keep the tasks in a separate repo.

## Run the evals

```bash
evals/run-evals.sh                     # every task
evals/run-evals.sh <name>              # one task
SETUP_CMD="npm ci" evals/run-evals.sh  # install dependencies first
```

For each task, the script does these steps:

1. It creates a git worktree at the `base` commit. A worktree is a second checkout of the repo in another folder.
2. It copies your current `CLAUDE.md`, `REVIEW.md`, and `.claude/` into the worktree, adds your current `.gitignore` lines, and commits them there. So it tests your new setup on the old code, and git is clean when Claude starts. The `.gitignore` lines matter: without them, screenshots from `verify-app` count as changes, and the Stop hook runs the checks again at every stop.
3. It runs `SETUP_CMD`, if you set one.
4. It runs `claude -p` in auto mode with `EVAL_NOTE` and the prompt. `-p` runs Claude once, without a session you type into. `EVAL_NOTE` says that no change folder is needed and that Claude must not create a branch, commit, or open a PR.
5. It runs `check.sh` in the worktree.
6. It removes the worktree, and deletes any branch that appeared during the task.

The script saves a log for each task in `evals/results/<date>/` and prints the pass count. Add `evals/results/` to `.gitignore`.

## Things to know

- **Each task is a full Claude run.** In the field test, one task took 3–4 minutes, because Claude also ran `verify-app` and `reviewer`. So 20–50 tasks take about 1.5–3.5 hours. Start with 3 tasks.
- **Your hooks run inside each eval too.** The Stop hook needs the project's dependencies, so set `SETUP_CMD`.
- **Do not create branches in the repo while the evals run.** The script deletes every branch that appears during a task.
- **One run can pass or fail by chance.** Before you trust a change in the pass count, run the evals again.
