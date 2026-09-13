# Example files

Copy these into the root of your project. Then change the commands to match your project.

```
examples/
├── CLAUDE.md                      → your-project/CLAUDE.md
├── REVIEW.md                      → what the reviewer reports
├── changes/
│   └── _template/                 → copy one file at a time to changes/<name>/
│       ├── INTENT.md              → stage 1: the problem and the outcome
│       ├── SPEC.md                → stage 2: acceptance criteria
│       └── PLAN.md                → stage 3: files, order of work, risks, proof
├── evals/
│   ├── README.md                  → how to add and run evals
│   ├── run-evals.sh               → runs past tasks to test your setup
│   └── tasks/
│       └── _example/
│           ├── base               → the commit to start from
│           ├── prompt.md          → the request
│           └── check.sh           → exits 0 if the result is correct
└── .claude/
    ├── settings.json              → hooks + allowed commands
    ├── loop.md                    → what /loop does after the PR opens
    ├── hooks/
    │   ├── format.sh              → formats each file Claude edits
    │   ├── protect-tests.sh       → blocks edits to tests that existed before the branch
    │   └── stop-verify.sh         → blocks "done" while checks fail
    ├── agents/
    │   ├── verify-app.md          → tests the change in the running app
    │   └── reviewer.md            → reviews the diff with the rules in REVIEW.md
    └── skills/
        └── api-security/
            └── SKILL.md           → example team rules, written as a skill
```

## Copy them

```bash
cp -r examples/.claude examples/CLAUDE.md examples/REVIEW.md examples/changes examples/evals /path/to/your-project/
chmod +x /path/to/your-project/.claude/hooks/*.sh /path/to/your-project/evals/run-evals.sh
printf '%s\n' '.claude/worktrees/' 'evals/results/' >> /path/to/your-project/.gitignore
```

- If your project already has `CLAUDE.md` or `.claude/settings.json`, merge them by hand. Do not overwrite.
- Also add the folder where Claude saves screenshots to `.gitignore`.
- If your lint or test tools scan the whole repo, add `.claude/worktrees/` and `evals/` to their ignore lists. Otherwise a parallel session or a hidden eval test makes them fail.

`jq` must be installed. All three hook scripts use it to read the JSON that Claude Code sends.

`/loop` uses `gh` (the GitHub CLI), so log in with `gh auth login` first. To push a change to a CI workflow file, the token also needs the `workflow` scope: `gh auth refresh -h github.com -s workflow`. An SSH remote (`git@github.com:<owner>/<repo>.git`) does not need that scope.

## What to change

| File | Change |
|---|---|
| `CLAUDE.md` | The install, start, lint, typecheck, and test commands. Which work needs a change folder. Delete the lines marked "Example" |
| `REVIEW.md` | What counts as Important, the paths to skip, and the checks for every PR |
| `changes/_template/*.md` | The sections your team needs |
| `.claude/hooks/format.sh` | The formatter for each file type |
| `.claude/hooks/protect-tests.sh` | `TEST_PATTERN`: which files are tests. It also matches helper files in a `tests/` folder, so Claude cannot edit them. `BASE_REF`: the branch with the tests to protect (default: the remote's default branch). If `origin/HEAD` is missing, run `git remote set-head origin -a` |
| `.claude/hooks/stop-verify.sh` | `VERIFY_CMD`: the command that must pass. `MAX_BLOCKS`: how many times it can block in a row (default 5). `DOCS_PATTERN`: files that do not need the checks (default: `changes/` and Markdown files) |
| `.claude/loop.md` | The check command. The CI commands, if you do not use GitHub Actions |
| `.claude/settings.json` | The commands in `permissions.allow` |
| `.claude/skills/` | Replace `api-security` with your team's rules. Use one folder for each skill |
| `evals/tasks/` | Real past tasks from your project. See [`evals/README.md`](evals/README.md) |

## How the Stop hook works

1. Claude tries to finish.
2. The hook takes a fingerprint of every file in the project, including files that are not committed.
   - If the fingerprint is the same as when the checks last passed, it skips the checks. A commit does not change the fingerprint.
   - If only files that match `DOCS_PATTERN` changed, it skips the checks.
   - Before the first pass in a session, it compares with the base branch. So work that Claude already committed on a branch is still checked.
3. Otherwise, the hook runs `VERIFY_CMD`.
   - If the check passes, Claude finishes.
   - If the check fails, the hook exits with code 2. Claude reads the last 40 lines of output and keeps working.
4. After `MAX_BLOCKS` failures in a row, the hook lets Claude stop, so a person can look.

## How the test protection hook works

1. Claude tries to change a file with an edit tool.
2. The hook checks the path against `TEST_PATTERN`. If the file is not a test, the edit goes ahead.
3. If the test file exists on `BASE_REF`, the hook exits with code 2. The edit is blocked. Claude reads the reason and fixes the code instead.
4. If the test file is new, the edit goes ahead. So Claude can still write failing tests first.
5. If `SPEC.md` says the old behavior was wrong, a person starts Claude with `ALLOW_TEST_EDITS=1`. Then the hook allows all test edits.

The hook does not see shell commands. `REVIEW.md` tells the reviewer to check that no old test changed.

This hook can shape the design. If an old test checks a whole response, Claude may add a new route instead of a new field, so that the old test stays the same.

## How the Stop hook, `/goal`, and `/loop` work together

| | Stop hook | `/goal` | `/loop` |
|---|---|---|---|
| Used for | Every session | Building one change | After the PR opens |
| Checks | Lint, typecheck, and tests really pass | The change is done, and a PR is open | CI and review comments |
| Who decides | The real command's exit code | A small, fast model that reads the conversation | Claude, on each check |
| Next turn starts | Right after the last turn | Right after the last turn | After a wait (Claude picks 1–60 minutes) |
| Stops when | Checks pass, nothing changed since the last pass, only documents changed, or 5 failures in a row | The model says "met" or "impossible", or you run `/goal clear` | The PR is merged or closed, or you press `Esc` |

Things to know:

- **Keep both the Stop hook and `/goal`.** Both run after every turn, at the same time. If either says "not done", Claude keeps working. The `/goal` model can be fooled by text that says "tests pass". The Stop hook cannot, because it runs the tests.
- **The `/goal` model does not read files or run commands.** It only reads the conversation. So the condition asks Claude to print the evidence in its last message.
- **A turn limit does not work.** One long build with many tool calls counts as one turn. To stop now, run `/goal clear` or press `Ctrl+C`. To see the time and turns, run `/goal` with no text. The token number there is lower than the real use.
- **Use the `verify-app` subagent, not `/verify`.** Claude cannot start `/verify` on its own. Only you can type it. Inside `/goal` or `/loop`, it does nothing.
- **Use `/loop` after the PR, not `/goal`.** CI and reviewers take minutes or hours. `/goal` starts the next turn right away, so it would use tokens while it waits. `/loop` waits between checks.
- **`loop.md` limits what `/loop` does.** Without it, bare `/loop` also runs cleanup passes, such as bug hunts and simplification. That adds changes to a PR that is under review.
- **`loop.md` does not code a request that the spec does not cover.** It lists the request for a person. Update `SPEC.md`, and the next check makes the change.
- **`/loop` needs the session to stay open.** If you close it, the loop stops. `--resume` does not restart a loop where Claude picks the wait, so run `/loop` again.

## Use it for one change

Replace `<name>` with a short name for the change, such as `display-name`.

```text
1. Create a branch:
   git switch main && git pull && git switch -c <name>

2. Write the intent (you answer each question):
   claude
   > Interview me about <idea>. Ask one question at a time. Then create changes/<name>/, copy only changes/_template/INTENT.md into it, and fill it in.
   Review INTENT.md with the checklist in README.md. Commit it.

3. Write the spec (same session is fine):
   > Read changes/<name>/INTENT.md. Write changes/<name>/SPEC.md from changes/_template/SPEC.md. Follow the project skills that apply. Ask me when INTENT.md does not answer a question.
   Review SPEC.md. Commit it.

4. Write the plan (a new session, in plan mode):
   claude --permission-mode plan
   > Read changes/<name>/SPEC.md. Interview me about anything the spec leaves open. Then write a plan with the sections in changes/_template/PLAN.md.
   Change the plan until a person who has not seen the conversation could build from it.
   When Claude asks "Would you like to proceed?", choose "Tell Claude what to change" and type:
   > Save the plan as changes/<name>/PLAN.md and stop. Do not write any code.
   (Both "Yes" options start coding in this session.) Review PLAN.md. Commit it.

5. Build it (a new session, so the context is clean):
   claude --permission-mode auto
   > /add-dir <screenshot folder>        (only if Claude saves screenshots outside the project)
   > /goal Every acceptance criterion in changes/<name>/SPEC.md is met, the work follows changes/<name>/PLAN.md, and a PR is open. Your last message must show: each criterion with its evidence, the passing output of npm run lint && npm run typecheck && npm test, verify-app returning RESULT: PASS, reviewer returning VERDICT: APPROVE, and the PR URL. No existing test was changed unless SPEC.md says the old behavior was wrong. If you cannot finish, stop and list what is left.

6. Look after the PR (another new session, on the same branch):
   claude --permission-mode auto
   > /loop

7. Review the PR and its evidence. Merge it. The loop sees the merge and stops.
```

## Use it for a bug fix

A bug fix does not need a change folder.

```text
git switch main && git pull && git switch -c fix-<name>
claude --permission-mode auto
> /goal <the bug, in one or two sentences> is fixed and a PR is open. Your last message must show: the name of a new test that failed before the fix and passes now, the passing output of npm run lint && npm run typecheck && npm test, reviewer returning VERDICT: APPROVE, and the PR URL. No existing test was changed. If you cannot finish, stop and list what is left.
```

## Run changes in parallel

Give each change its own worktree. A worktree is a second checkout of the repo in another folder, on its own branch. `claude --worktree` starts the new branch from the branch you are on, so switch to `main` first:

```bash
git switch main
claude --worktree display-name      # in one terminal
claude --worktree fix-rate-limit    # in another terminal
```

Claude Code puts each worktree in `.claude/worktrees/<name>`, inside your project. Add that folder to `.gitignore` and to your lint and test ignore lists. Otherwise the main folder is never clean, and a tool such as `eslint .` also scans the worktree.

Start with 2–3 sessions. Add more only while you can still review every PR properly.

## Test your setup with evals

Each change to `CLAUDE.md`, a skill, a hook, or a subagent changes how Claude works. Run the evals after each of these changes. See [`evals/README.md`](evals/README.md).
