# Sources

Research done 13 Sep 2026.

| Claim | Source |
|---|---|
| Verification, plan mode, test-first, SPEC.md interview, auto mode, sandbox | https://code.claude.com/docs/en/best-practices |
| `/run`, `/verify`, `/run-skill-generator` are bundled skills | https://code.claude.com/docs/en/skills ("Run and verify your app") |
| Four kinds of loop (turn-based, goal-based, time-based, proactive); `/loop 5m check my PR, address review comments, and fix failing CI`; `/schedule` + `/goal` for proactive loops | https://claude.com/blog/getting-started-with-loops |
| `/goal` keeps Claude working until a condition is met; it wraps a prompt-based Stop hook; a small fast model judges the condition from the conversation only and does not run commands or read files; a turn limit is a clause in the condition, judged by the model; `/goal clear`; `/goal` alone shows turns and token spend; auto mode needed to run unattended | https://code.claude.com/docs/en/goal |
| Stop hooks: `{"decision": "block"}` or exit code 2; check `stop_hook_active`; overridden after 8 blocks in a row without progress; all matching hooks run in parallel | https://code.claude.com/docs/en/hooks-guide and https://code.claude.com/docs/en/hooks |
| `/loop` with no interval lets Claude pick a wait of 1–60 minutes and stop itself; `Esc` stops it; bare `/loop` runs a built-in prompt that includes cleanup passes, or `.claude/loop.md` instead; fixed-interval tasks expire after 7 days; a self-paced loop is not restored on `--resume`; skills with `disable-model-invocation: true`, including `/verify`, arrive as plain text; routines | https://code.claude.com/docs/en/scheduled-tasks |
| `disable-model-invocation: true` hides a skill from Claude's list, so only you can start it | https://code.claude.com/docs/en/skills |
| Bash rule syntax `Bash(gh pr view *)`; each part of a `&&` command is matched on its own | https://code.claude.com/docs/en/permissions |
| Planner / generator / evaluator harness; agents grade their own work too kindly; 6 h and $200 vs 20 min and $9 | https://www.anthropic.com/engineering/harness-design-long-running-apps (24 Mar 2026) |
| Boris's setup: CLAUDE.md in git, slash commands, `code-simplifier` and `verify-app` subagents, PostToolUse format hook, `/permissions`, 2–3x quote | https://x.com/bcherny/status/2007179850139000872 (Jan 2026) |
| Boris uses auto mode more than plan mode; Cat Wu's app-testing skill | https://www.theneuron.ai/explainer-articles/claude-code-creators-boris-cherny-and-cat-wu-explain-how-to-use-agent-loops/ (9 Jun 2026) |
| Ralph Wiggum loop plugin | https://github.com/anthropics/claude-code/blob/main/plugins/ralph-wiggum/README.md |

## Not fully confirmed

- The "2–3x better" figure is Boris's estimate, not a measured test.
- Boris's April 2026 `/go` skill (test, simplify, open PR) comes from a secondary summary only: https://github.com/shanraisshan/claude-code-best-practice/blob/main/tips/claude-boris-6-tips-16-apr-26.md
- The GitHub app install command: Boris's thread says `/install-github-action`; the docs may say `/install-github-app`. Not checked.
