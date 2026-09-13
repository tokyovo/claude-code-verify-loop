# Claude Code verify loop

A setup guide. The goal: you describe a feature, and Claude Code plans it, builds it, tests it, fixes its own mistakes, opens a PR, and looks after the PR until it is merged.

This repo holds the guide so we can review it, test it on real projects, and improve it.

## The main idea

Two things make it work:

1. **A check Claude can run that says pass or fail.** For example: tests, typecheck, lint, or Claude using the real app in a browser.
2. **A rule that stops Claude from finishing until the check passes.** For example: `/goal`, or a Stop hook (a script that runs each time Claude tries to finish).

Boris Cherny (creator of Claude Code) says this feedback loop makes the result 2–3 times better. This is his estimate, not a measured test.

## The loop

```
You: SPEC.md → /goal: Plan → Build → Verify ──pass──→ Review (2nd agent) → PR
                               ↑        │                  │               │
                               └─ fail ─┘                  │               │
                               ↑                           │               │
                               └──── problems found ───────┘               │
                                                                           ▼
                              /loop: check CI and review comments → fix → push
                              (waits between checks, stops when the PR is merged)
```

## The six parts

| Part | What it does | How to set it up |
|---|---|---|
| Pass/fail check | Claude knows if its work is correct | Put the test, lint, and typecheck commands in `CLAUDE.md`. Ask Claude to show the command and its output. |
| Test the real app | Catches bugs that unit tests miss | Run `/run-skill-generator` once. It saves how to start your app. Then `/run` and `/verify` use it. |
| Do not stop until it passes | Claude keeps working until done | `/goal` for the feature, plus a Stop hook that runs the real tests |
| Separate reviewer | Agents rate their own work too kindly | A reviewer subagent in `.claude/agents/`, or `/code-review` |
| No permission prompts | Claude runs without waiting for you | Auto mode: `claude --permission-mode auto`, plus `/sandbox` |
| Many sessions at once | More work in parallel | Git worktrees, web sessions, `/loop`, routines |

## Which loop for which step

A loop is Claude repeating work until a stop condition is met. Each step of a feature uses a different kind.

| Step | Kind of loop | Command | Next turn starts | Ends when |
|---|---|---|---|---|
| Write `SPEC.md` | Turn-based | A normal prompt | You answer | `SPEC.md` is written |
| Build the feature | Goal-based | `/goal <condition>` | Right away | A model confirms the condition is met |
| After the PR | Time-based | `/loop` with `.claude/loop.md` | After a wait | The PR is merged or closed |
| Later: recurring work | Proactive | `/schedule` + `/goal` | On a schedule | You stop the routine. **Not in this setup yet.** |

Why this split:

- **`/goal` for building.** "Done" is clear and Claude can prove it: the criteria, the checks, and an open PR.
- **`/loop` for the PR.** CI and reviewers are outside Claude's control and take time. `/loop` waits between checks. `/goal` would start the next turn right away and use tokens while it waits.
- **The Stop hook stays on in both.** `/goal` is judged by a model that only reads the conversation. The Stop hook runs the real tests.

See [`examples/README.md`](examples/README.md) for the exact `/goal` condition and how the three tools work together.

## Setup steps

1. Write a short `CLAUDE.md` with your test, lint, and typecheck commands. Add a rule each time Claude makes a mistake.
2. Add a PostToolUse hook on `Edit|Write` that runs your formatter.
3. Run `/run-skill-generator` so Claude can start and use your app.
4. Add two subagents: `verify-app` (end-to-end test steps) and a reviewer.
5. Turn on auto mode and `/sandbox`.
6. For each feature, ask Claude to interview you and write `SPEC.md` with acceptance criteria.
7. In a new session, run `/goal` with the condition from `examples/README.md`. Claude builds, checks, reviews, and opens a PR.
8. In another new session, run `/loop`. It follows `.claude/loop.md`: it fixes failed CI and review comments until the PR is merged.
9. Review the evidence and merge the PR.

## Watch out

- **No check, no loop.** Without a real test, Claude "passes" by saying it is done.
- **Always set a limit** on turns or loops. In `/goal`, "stop after 30 turns" is judged by a model, not enforced. Check it with `/goal`. Stop it with `/goal clear`.
- **The `/goal` judge cannot see files.** It only reads the conversation. Ask Claude to print the evidence in its last message.
- **Claude cannot start `/verify` on its own.** Use the `verify-app` subagent inside `/goal` and `/loop`.
- **Cost adds up.** Anthropic's 3-agent test took 6 hours and $200. One agent took 20 minutes and $9, but its result was worse. Each `/loop` check also costs tokens, even when nothing changed.
- **A reviewer can push too hard.** If it reports style issues, Claude adds code it does not need.
- Boris does **not** skip permissions. He uses auto mode and pre-approved safe commands.

## Files

- [`examples/`](examples/): example `CLAUDE.md`, `SPEC.md`, `loop.md`, hooks, and subagents to copy into a project
- [`docs/summary.html`](docs/summary.html): the one-page visual summary
- [`docs/sources.md`](docs/sources.md): where each claim comes from
- [`docs/open-questions.md`](docs/open-questions.md): things to check and improve

## Status

First draft, 13 Sep 2026. Not yet tested on a real project.
