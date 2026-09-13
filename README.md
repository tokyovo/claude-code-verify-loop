# Claude Code verify loop

A setup guide. The goal: you describe a feature, and Claude Code plans it, builds it, tests it, fixes its own mistakes, and opens a PR.

This repo holds the guide so we can review it, test it on real projects, and improve it.

## The main idea

Two things make it work:

1. **A check Claude can run that says pass or fail.** For example: tests, typecheck, lint, or Claude using the real app in a browser.
2. **A rule that stops Claude from finishing until the check passes.** For example: `/goal`, or a Stop hook (a script that runs each time Claude tries to finish).

Boris Cherny (creator of Claude Code) says this feedback loop makes the result 2–3 times better. This is his estimate, not a measured test.

## The loop

```
You (feature + "done" rule) → Plan → Build → Verify ──pass──→ Review (2nd agent) → PR
                                       ↑        │                  │
                                       └─ fail ─┘                  │
                                       ↑                           │
                                       └──── problems found ───────┘
```

## The six parts

| Part | What it does | How to set it up |
|---|---|---|
| Pass/fail check | Claude knows if its work is correct | Put the test, lint, and typecheck commands in `CLAUDE.md`. Ask Claude to show the command and its output. |
| Test the real app | Catches bugs that unit tests miss | Run `/run-skill-generator` once. It saves how to start your app. Then `/run` and `/verify` use it. |
| Do not stop until it passes | Claude keeps working until done | `/goal all tests pass and lint is clean, or stop after 20 turns`, or a Stop hook |
| Separate reviewer | Agents rate their own work too kindly | A reviewer subagent in `.claude/agents/`, or `/code-review` |
| No permission prompts | Claude runs without waiting for you | Auto mode: `claude --permission-mode auto`, plus `/sandbox` |
| Many sessions at once | More work in parallel | Git worktrees, web sessions, `/loop`, routines |

## Setup steps

1. Write a short `CLAUDE.md` with your test, lint, and typecheck commands. Add a rule each time Claude makes a mistake.
2. Add a PostToolUse hook on `Edit|Write` that runs your formatter.
3. Run `/run-skill-generator` so Claude can start and use your app.
4. Add two subagents: `verify-app` (end-to-end test steps) and a reviewer.
5. Turn on auto mode and `/sandbox`.
6. For each feature, ask Claude to interview you and write `SPEC.md` with acceptance criteria. Then, in a new session, run `/goal <criteria> verified, tests pass`.
7. Review the evidence and the PR.

## Watch out

- **No check, no loop.** Without a real test, Claude "passes" by saying it is done.
- **Always set a limit** on turns or loops.
- **Cost adds up.** Anthropic's 3-agent test took 6 hours and $200. One agent took 20 minutes and $9, but its result was worse.
- **A reviewer can push too hard.** If it reports style issues, Claude adds code it does not need.
- Boris does **not** skip permissions. He uses auto mode and pre-approved safe commands.

## Files

- [`docs/summary.html`](docs/summary.html): the one-page visual summary
- [`docs/sources.md`](docs/sources.md): where each claim comes from
- [`docs/open-questions.md`](docs/open-questions.md): things to check and improve

## Status

First draft, 13 Sep 2026. Not yet tested on a real project.
