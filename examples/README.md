# Example files

Copy these into the root of your project. Then change the commands to match your project.

```
examples/
├── CLAUDE.md                      → your-project/CLAUDE.md
├── SPEC.md                        → template for each feature
└── .claude/
    ├── settings.json              → hooks + allowed commands
    ├── loop.md                    → what /loop does after the PR opens
    ├── hooks/
    │   ├── format.sh              → formats each file Claude edits
    │   └── stop-verify.sh         → blocks "done" while checks fail
    └── agents/
        ├── verify-app.md          → tests the change in the running app
        └── reviewer.md            → reviews the diff for real bugs only
```

## Copy them

```bash
cp -r examples/.claude examples/CLAUDE.md /path/to/your-project/
chmod +x /path/to/your-project/.claude/hooks/*.sh
```

If your project already has `CLAUDE.md` or `.claude/settings.json`, merge them by hand. Do not overwrite.

`jq` must be installed. Both hook scripts use it to read the JSON that Claude Code sends. `/loop` uses `gh` (the GitHub CLI), so log in with `gh auth login` first.

## What to change

| File | Change |
|---|---|
| `CLAUDE.md` | The install, start, lint, typecheck, and test commands |
| `.claude/hooks/format.sh` | The formatter for each file type |
| `.claude/hooks/stop-verify.sh` | `VERIFY_CMD`: the command that must pass. `MAX_BLOCKS`: how many times it can block in a row (default 5) |
| `.claude/loop.md` | The check command. The CI commands, if you do not use GitHub Actions |
| `.claude/settings.json` | The commands in `permissions.allow` |

## How the Stop hook works

1. Claude tries to finish.
2. The hook runs `VERIFY_CMD`.
   - If git shows no changes, it skips the check.
   - If the check passes, Claude finishes.
   - If the check fails, the hook exits with code 2. Claude reads the last 40 lines of output and keeps working.
3. After `MAX_BLOCKS` failures in a row, the hook lets Claude stop, so a person can look.

## How the Stop hook, `/goal`, and `/loop` work together

| | Stop hook | `/goal` | `/loop` |
|---|---|---|---|
| Used for | Every session | Building one feature | After the PR opens |
| Checks | Lint, typecheck, and tests really pass | The feature is done, and a PR is open | CI and review comments |
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

## Use it for one feature

```text
1. Write the spec (you answer each question):
   claude
   > Interview me about <feature>. Ask one question at a time. Then write SPEC.md from the template.

2. Build it (a new session, so the context is clean):
   claude --permission-mode auto
   > /goal Every acceptance criterion in SPEC.md is met and a PR is open. Your last message must show: each criterion with its evidence, the passing output of npm run lint && npm run typecheck && npm test, verify-app returning RESULT: PASS, reviewer returning VERDICT: APPROVE, and the PR URL. No existing test was changed unless SPEC.md says the old behavior was wrong. Or stop after 30 turns and list what is left.

3. Look after the PR (another new session, on the same branch):
   claude --permission-mode auto
   > /loop

4. Review the PR and its evidence. Merge it. The loop sees the merge and stops.
```
