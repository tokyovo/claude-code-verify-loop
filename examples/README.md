# Example files

Copy these into the root of your project. Then change the commands to match your project.

```
examples/
├── CLAUDE.md                      → your-project/CLAUDE.md
├── SPEC.md                        → template for each feature
└── .claude/
    ├── settings.json              → hooks + allowed commands
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

`jq` must be installed. Both hook scripts use it to read the JSON that Claude Code sends.

## What to change

| File | Change |
|---|---|
| `CLAUDE.md` | The install, start, lint, typecheck, and test commands |
| `.claude/hooks/format.sh` | The formatter for each file type |
| `.claude/hooks/stop-verify.sh` | `VERIFY_CMD`: the command that must pass. `MAX_BLOCKS`: how many times it can block in a row (default 5) |
| `.claude/settings.json` | The commands in `permissions.allow` |

## How the Stop hook works

1. Claude tries to finish.
2. The hook runs `VERIFY_CMD`.
   - If git shows no changes, it skips the check.
   - If the check passes, Claude finishes.
   - If the check fails, the hook exits with code 2. Claude reads the last 40 lines of output and keeps working.
3. After `MAX_BLOCKS` failures in a row, the hook lets Claude stop, so a person can look.

## Not in these files

- **Auto mode.** Claude Code ignores `"defaultMode": "auto"` in project settings. Put it in your own `~/.claude/settings.json`, or start with `claude --permission-mode auto`.
- **Run skill.** Run `/run-skill-generator` once in your project. It writes `.claude/skills/run-<name>/` for you.

## Use it for one feature

```text
1. claude
   > Interview me about <feature>. Ask one question at a time. Then write SPEC.md from the template.
2. Start a new session:
   claude --permission-mode auto
   > /goal Every acceptance criterion in SPEC.md is met, verify-app returns PASS, reviewer returns APPROVE, and tests pass. Stop after 30 turns.
3. Review the PR and its evidence.
```
