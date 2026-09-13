# Sources

Research done 13 Sep 2026.

| Claim | Source |
|---|---|
| Verification, plan mode, test-first, SPEC.md interview, auto mode, sandbox | https://code.claude.com/docs/en/best-practices |
| `/run`, `/verify`, `/run-skill-generator` are bundled skills | https://code.claude.com/docs/en/skills ("Run and verify your app") |
| Four kinds of loop (turn-based, goal-based, time-based, proactive); `/loop 5m check my PR, address review comments, and fix failing CI`; `/schedule` + `/goal` for proactive loops | https://claude.com/blog/getting-started-with-loops |
| `/goal` keeps Claude working until a condition is met; it wraps a prompt-based Stop hook; a small fast model judges the condition from the conversation only and does not run commands or read files; a turn limit is a clause in the condition, judged by the model; `/goal clear`; `/goal` alone shows turns and token spend; auto mode needed to run unattended | https://code.claude.com/docs/en/goal |
| Stop hooks: `{"decision": "block"}` or exit code 2; check `stop_hook_active`; overridden after 8 blocks in a row without progress; all matching hooks run in parallel | https://code.claude.com/docs/en/hooks-guide and https://code.claude.com/docs/en/hooks |
| PreToolUse hooks: exit code 2 blocks the tool call; the hook reads `tool_input.file_path` from stdin; example script that blocks edits to protected files | https://code.claude.com/docs/en/hooks and https://code.claude.com/docs/en/hooks-guide ("Block edits to protected files") |
| `/loop` with no interval lets Claude pick a wait of 1–60 minutes and stop itself; `Esc` stops it; bare `/loop` runs a built-in prompt that includes cleanup passes, or `.claude/loop.md` instead; fixed-interval tasks expire after 7 days; a self-paced loop is not restored on `--resume`; skills with `disable-model-invocation: true`, including `/verify`, arrive as plain text; routines | https://code.claude.com/docs/en/scheduled-tasks |
| `disable-model-invocation: true` hides a skill from Claude's list, so only you can start it | https://code.claude.com/docs/en/skills |
| Bash rule syntax `Bash(gh pr view *)`; each part of a `&&` command is matched on its own | https://code.claude.com/docs/en/permissions |
| `claude --worktree [name]` creates a git worktree for the session; `--permission-mode` accepts `plan` and `auto` | `claude --help` on Claude Code 2.1.270 |
| Six SDLC stages (Plan, Design, Build, Test, Deploy, Maintain); code is no longer the slow part; each stage commits a file the next stage reads, and the commits are the audit trail | https://claude.com/blog/the-ai-native-sdlc-playbook (Louis Claxton, 21 Aug 2026) |
| `intent.md` sections: problem, proposed outcome, affected users and systems, constraints, open questions. `spec.md` is written from the accepted intent and guided by skills; the product owner checks it against the intent. `plan.md` is written in plan mode; iterate until an engineer who never saw the conversation could build from it; sections: files that change, order of work, risks, proof | Same playbook, stages 1–3 |
| `CLAUDE.md`: build, test, and lint commands, conventions, and what Claude gets wrong; under a page; add a correction when Claude makes a mistake twice. Skills in `.claude/skills/<name>/SKILL.md` with frontmatter that says when they trigger. Hooks block edits to protected paths; a hook that asks a person for approval belongs in the Deploy stage. 2–3 parallel sessions to start; `claude --worktree <name>` | Same playbook, stage 3 |
| Always give Claude a way to verify its work; hooks block edits to protected paths; 20–50 real tasks as evals, run on a schedule and on changes to `CLAUDE.md`, skills, or hooks | Same playbook, stage 4 |
| `REVIEW.md` with passes for bugs, security, and compliance; "Important" reserved for broken behavior, leaked data, or a broken policy; at most five nits; deploy approval hook with exit code 2; `claude -p` in CI; tiered autonomy per environment; rollback as the most rehearsed path | Same playbook, stage 5 |
| Maintain stage: a script invokes Claude when a control band is breached, and Claude writes its diagnosis as `intent.md`; Claude Tag; Claude Security; managed settings; source of truth options; measurement indicators | Same playbook, stage 6 and side sections |
| `REVIEW.md` at the repo root tunes the managed Code Review service; severities Important, Nit, Pre-existing; a nit cap is a common rule; the local `/code-review` command does not read `REVIEW.md`; research preview for Team and Enterprise | https://code.claude.com/docs/en/code-review |
| Planner / generator / evaluator harness; agents grade their own work too kindly; 6 h and $200 vs 20 min and $9 | https://www.anthropic.com/engineering/harness-design-long-running-apps (24 Mar 2026) |
| Boris's setup: CLAUDE.md in git, slash commands, `code-simplifier` and `verify-app` subagents, PostToolUse format hook, `/permissions`, 2–3x quote | https://x.com/bcherny/status/2007179850139000872 (Jan 2026) |
| Boris uses auto mode more than plan mode; Cat Wu's app-testing skill | https://www.theneuron.ai/explainer-articles/claude-code-creators-boris-cherny-and-cat-wu-explain-how-to-use-agent-loops/ (9 Jun 2026) |
| Ralph Wiggum loop plugin | https://github.com/anthropics/claude-code/blob/main/plugins/ralph-wiggum/README.md |

## Not fully confirmed

- The "2–3x better" figure is Boris's estimate, not a measured test.
- Boris's April 2026 `/go` skill (test, simplify, open PR) comes from a secondary summary only: https://github.com/shanraisshan/claude-code-best-practice/blob/main/tips/claude-boris-6-tips-16-apr-26.md
- The GitHub app install command: Boris's thread says `/install-github-action`; the docs may say `/install-github-app`. Not checked.
- The playbook was read through a fetch tool that summarizes pages. Check these against the page: the exact list of measurement indicators, the product status labels for Claude Tag and Claude Security, and the permissions for the staging environment.
- The managed settings keys `allowManagedHooksOnly` and `strictKnownMarketplaces` come from the playbook only. They are not on https://code.claude.com/docs/en/settings. They may be on the managed settings page. Not checked.
- These choices are this guide's, not the playbook's: the `changes/<name>/` folder for each change, capital-letter file names, protecting only tests that exist on the base branch, and using the eval pass count as a measure.
- The playbook says to add a rule after the same mistake happens twice. Boris's thread says to add a rule each time Claude does something wrong. This guide follows the playbook.
