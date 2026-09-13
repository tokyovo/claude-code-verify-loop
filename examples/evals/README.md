# Evals: test your setup

An eval is a real past task with a known correct result. You give the task to Claude, then check the result.

Your `CLAUDE.md`, skills, hooks, and subagents control how Claude works. A change to one of them can make Claude worse, and nobody notices. Run the evals after each change to them. Compare the pass count with the last run.

## Add a task

1. Pick a real change that your team merged. Over time, collect 20–50 of them. Include past bugs, so they stay fixed.
2. Copy `tasks/_example/` to `tasks/<name>/`.
3. In `base`, write the commit before that change.
4. In `prompt.md`, write the request as a person gave it.
5. In `check.sh`, write a check that exits 0 when the result is correct. A good check runs the tests from the real merged change.

## Run the evals

```bash
evals/run-evals.sh                   # every task
evals/run-evals.sh <name>            # one task
SETUP_CMD="npm ci" evals/run-evals.sh  # install dependencies first
```

For each task, the script does these steps:

1. It creates a git worktree at the `base` commit. A worktree is a second checkout of the repo in another folder.
2. It copies your current `CLAUDE.md`, `REVIEW.md`, and `.claude/` into the worktree. So it tests your new setup on the old code.
3. It runs `SETUP_CMD`, if you set one.
4. It runs `claude -p` with the prompt, in auto mode. `-p` runs Claude once, without a session you type into.
5. It runs `check.sh` in the worktree.
6. It removes the worktree.

The script saves a log for each task in `evals/results/<date>/` and prints the pass count. Add `evals/results/` to `.gitignore`.

## Things to know

- Each task is a full Claude run. It costs tokens and time. Start with 3 tasks.
- Your hooks run inside each eval too. The Stop hook needs the project's dependencies, so set `SETUP_CMD`.
- One run can pass or fail by chance. Before you trust a change in the pass count, run the evals again.
