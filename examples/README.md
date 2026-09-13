# Example files

Copy these into the root of your project. Then change the commands to match your project.

```
examples/
├── CLAUDE.md                      → your-project/CLAUDE.md
├── REVIEW.md                      → what the reviewer reports
├── changes/
│   └── _template/                 → copy to changes/<name>/ for each change
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
```

If your project already has `CLAUDE.md` or `.claude/settings.json`, merge them by hand. Do not overwrite.

`jq` must be installed. All three hook scripts use it to read the JSON that Claude Code sends. `/loop` uses `gh` (the GitHub CLI), so log in with `gh auth login` first.

## What to change

| File | Change |
|---|---|
| `CLAUDE.md` | The install, start, lint, typecheck, and test commands |
| `REVIEW.md` | What counts as Important, the paths to skip, and the checks for every PR |
| `changes/_template/*.md` | The sections your team needs |
| `.claude/hooks/format.sh` | The formatter for each file type |
| `.claude/hooks/protect-tests.sh` | `TEST_PATTERN`: which files are tests. `BASE_REF`: the branch with the tests to protect (default: the remote's default branch) |
| `.claude/hooks/stop-verify.sh` | `VERIFY_CMD`: the command that must pass. `MAX_BLOCKS`: how many times it can block in a row (default 5) |
| `.claude/loop.md` | The check command. The CI commands, if you do not use GitHub Actions |
| `.claude/settings.json` | The commands in `permissions.allow` |
| `.claude/skills/` | Replace `api-security` with your team's rules. Use one folder for each skill |
| `evals/tasks/` | Real past tasks from your project. See [`evals/README.md`](evals/README.md) |

## How the Stop hook works

1. Claude tries to finish.
2. The hook runs `VERIFY_CMD`.
   - If git shows no changes, it skips the check.
   - If the check passes, Claude finishes.
   - If the check fails, the hook exits with code 2. Claude reads the last 40 lines of output and keeps working.
3. After `MAX_BLOCKS` failures in a row, the hook lets Claude stop, so a person can look.

## How the test protection hook works

1. Claude tries to change a file with an edit tool.
2. The hook checks the path against `TEST_PATTERN`. If the file is not a test, the edit goes ahead.
3. If the test file exists on `BASE_REF`, the hook exits with code 2. The edit is blocked. Claude reads the reason and fixes the code instead.
4. If the test file is new, the edit goes ahead. So Claude can still write failing tests first.
5. If `SPEC.md` says the old behavior was wrong, a person starts Claude with `ALLOW_TEST_EDITS=1`. Then the hook allows all test edits.

The hook does not see shell commands. `REVIEW.md` tells the reviewer to check that no old test changed.

## How the Stop hook, `/goal`, and `/loop` work together

| | Stop hook | `/goal` | `/loop` |
|---|---|---|---|
| Used for | Every session | Building one change | After the PR opens |
| Checks | Lint, typecheck, and tests really pass | The change is done, and a PR is open | CI and review comments |
| Who decides | The real command's exit code | A small, fast model that reads the conversation | Claude, on each check |
| Next turn starts | Right after the last turn | Right after the last turn | After a wait (Claude picks 1–60 minutes) |
| Stops when | Checks pass, git is clean, or 5 failures in a row | The model says "met" or "impossible", or you run `/goal clear` | The PR is merged or closed, or you press `Esc` |

Things to know:

- **Keep both the Stop hook and `/goal`.** Both run after every turn, at the same time. If either says "not done", Claude keeps working. The `/goal` model can be fooled by text that says "tests pass". The Stop hook cannot, because it runs the tests.
- **The `/goal` model does not read files or run commands.** It only reads the conversation. So the condition asks Claude to print the evidence in its last message.
- **"Stop after 30 turns" is not a hard limit.** The model judges it from the conversation. To stop now, run `/goal clear` or press `Ctrl+C`. To see turns and token cost, run `/goal` with no text.
- **Use the `verify-app` subagent, not `/verify`.** Claude cannot start `/verify` on its own. Only you can type it. Inside `/goal` or `/loop`, it does nothing.
- **Use `/loop` after the PR, not `/goal`.** CI and reviewers take minutes or hours. `/goal` starts the next turn right away, so it would use tokens while it waits. `/loop` waits between checks.
- **`loop.md` limits what `/loop` does.** Without it, bare `/loop` also runs cleanup passes, such as bug hunts and simplification. That adds changes to a PR that is under review.
- **`/loop` needs the session to stay open.** If you close it, the loop stops. `--resume` does not restart a loop where Claude picks the wait, so run `/loop` again.

## Use it for one change

Replace `<name>` with a short name for the change, such as `display-name`.

```text
1. Write the intent (you answer each question):
   claude
   > Interview me about <idea>. Ask one question at a time. Then copy changes/_template/ to changes/<name>/ and fill in INTENT.md.
   Review INTENT.md. Commit it.

2. Write the spec (same session is fine):
   > Read changes/<name>/INTENT.md. Write changes/<name>/SPEC.md from the template. Follow the project skills that apply. Ask me when INTENT.md does not answer a question.
   Check that SPEC.md solves the problem in INTENT.md. Commit it.

3. Write the plan (a new session, in plan mode):
   claude --permission-mode plan
   > Read changes/<name>/SPEC.md. Interview me about anything the spec leaves open. Then write a plan with the sections in changes/_template/PLAN.md.
   Change the plan until a person who has not seen the conversation could build from it.
   Approve it. Ask Claude to save it as changes/<name>/PLAN.md. Commit it.

4. Build it (a new session, so the context is clean):
   claude --permission-mode auto
   > /goal Every acceptance criterion in changes/<name>/SPEC.md is met, the work follows changes/<name>/PLAN.md, and a PR is open. Your last message must show: each criterion with its evidence, the passing output of npm run lint && npm run typecheck && npm test, verify-app returning RESULT: PASS, reviewer returning VERDICT: APPROVE, and the PR URL. No existing test was changed unless SPEC.md says the old behavior was wrong. Or stop after 30 turns and list what is left.

5. Look after the PR (another new session, on the same branch):
   claude --permission-mode auto
   > /loop

6. Review the PR and its evidence. Merge it. The loop sees the merge and stops.
```

## Run changes in parallel

Give each change its own worktree. A worktree is a second checkout of the repo in another folder, on its own branch:

```bash
claude --worktree display-name      # in one terminal
claude --worktree fix-rate-limit    # in another terminal
```

Start with 2–3 sessions. Add more only while you can still review every PR properly.

## Test your setup with evals

Each change to `CLAUDE.md`, a skill, a hook, or a subagent changes how Claude works. Run the evals after each of these changes. See [`evals/README.md`](evals/README.md).
