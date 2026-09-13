# Claude Code verify loop

A setup guide. The goal: you describe a change, and Claude Code plans it, builds it, tests it, fixes its own mistakes, opens a PR, and looks after the PR until it is merged. You review each written step and merge the result.

This repo holds the guide so we can review it, test it on real projects, and improve it. The first test on a real project is in [`docs/field-tests/2026-09-13-shelf.md`](docs/field-tests/2026-09-13-shelf.md).

## The main idea

Three things make it work:

1. **A check Claude can run that says pass or fail.** For example: tests, typecheck, lint, or Claude using the real app in a browser.
2. **A rule that stops Claude from finishing until the check passes.** For example: `/goal`, or a Stop hook (a script that runs each time Claude tries to finish).
3. **Each step writes a file that the next step reads.** A person reviews each file and commits it. The files and the commits show who asked for what, what Claude built, and who approved it.

Boris Cherny (creator of Claude Code) says the feedback loop in ideas 1 and 2 makes the result 2–3 times better. This is his estimate, not a measured test. Idea 3 comes from Anthropic's "AI-native SDLC playbook" (August 2026).

## How this setup maps to the playbook

SDLC means the software development lifecycle: every step from an idea to running software. The playbook splits it into six stages. Its main point: Claude now writes code in hours, so the slow parts are the steps before and after the code.

This setup covers stages 1 to 5 inside one repo. It stops at the merge. It does not deploy.

| Stage | What happens | In this setup | File it writes |
|---|---|---|---|
| 1. Plan | Claude interviews you about the idea | A normal prompt | `INTENT.md` |
| 2. Design | Claude turns the intent into criteria you can test, and follows your team's rules | A normal prompt, plus skills in `.claude/skills/` | `SPEC.md` |
| 3. Build | Claude writes a plan. You approve it. Then Claude builds it | Plan mode, then `/goal` | `PLAN.md`, then the code |
| 4. Test | Claude checks its own work before a person sees it | Stop hook, `verify-app`, test protection hook, evals | Evidence in the PR |
| 5. Deploy | A second agent reviews the change. Claude fixes CI failures and review comments | `reviewer` with `REVIEW.md`, then `/loop` | The PR and the review findings |
| 6. Maintain | An alert, a ticket, or a schedule starts Claude without a person | **Not in this setup yet.** See "Later" below | — |

Each change has its own branch and its own folder, `changes/<name>/`, for its three files. So parallel sessions do not edit the same file.

## Which work needs the full flow

- **New behavior** (a new feature, or a change to how the app works): write `INTENT.md`, `SPEC.md`, and `PLAN.md` first.
- **A bug fix** (the app does not do what it already should): skip the three files. Ask for a failing test that shows the bug, then the fix. `examples/README.md` has a short `/goal` condition for this.
- **Runs with no person to answer**, such as evals: say in the prompt that no change folder is needed. Otherwise the "spec first" rule makes Claude write drafts and stop to ask.

## The loop

```
You + Claude:  INTENT.md → SPEC.md → PLAN.md    (you review and commit each file)
                                        │
                 ┌──────────────────────┘
                 ▼
       /goal:  Build → Verify ──pass──→ Review (2nd agent) → PR
                 ↑        │                  │               │
                 └─ fail ─┘                  │               │
                 ↑                           │               │
                 └──── problems found ───────┘               │
                                                             ▼
               /loop: check CI and review comments → fix → push
               (waits between checks, stops when the PR is merged)
```

## The eight parts

| Part | What it does | How to set it up |
|---|---|---|
| One file per step | You check each decision before Claude builds | `INTENT.md`, `SPEC.md`, and `PLAN.md` in `changes/<name>/`, on a branch for the change. Commit each file after you review it. |
| Team rules as skills | Claude follows the same rules in every spec and review | A skill (a folder with a `SKILL.md` file) in `.claude/skills/<name>/`. When a rule changes, change the skill. |
| Pass/fail check | Claude knows if its work is correct | Put the build, test, lint, and typecheck commands in `CLAUDE.md`. Keep `CLAUDE.md` under one page. Ask Claude to show the command and its output. |
| Test the real app | Catches bugs that unit tests miss | Run `/run-skill-generator` once. It saves how to start your app. Then `/run` and `/verify` use it. Keep screenshots inside the project, in a git-ignored folder. |
| Do not stop until it passes | Claude keeps working until done, and cannot weaken old tests | `/goal` for the change, a Stop hook that runs the real tests when the code changed, and a PreToolUse hook (a script that runs before each tool call) that blocks edits to old tests |
| Separate reviewer | Agents rate their own work too kindly | A reviewer subagent in `.claude/agents/` that follows `REVIEW.md`. Or `/code-review` |
| No permission prompts | Claude runs without waiting for you | Auto mode: `claude --permission-mode auto`, plus `/sandbox` |
| Many sessions at once | More work in parallel | `claude --worktree <name>` for each change, started from `main`. Add `.claude/worktrees/` to `.gitignore`. Start with 2–3 sessions. Also web sessions, `/loop`, and routines |

## Which loop for which step

A loop is Claude repeating work until a stop condition is met. Each step of a change uses a different kind.

| Step | Kind of loop | Command | Next turn starts | Ends when |
|---|---|---|---|---|
| Write `INTENT.md` and `SPEC.md` | Turn-based | A normal prompt | You answer | You accept the file |
| Write `PLAN.md` | Turn-based | `claude --permission-mode plan` | You answer | You approve the plan, and Claude saves it |
| Build the change | Goal-based | `/goal <condition>` | Right away | A model confirms the condition is met |
| After the PR | Time-based | `/loop` with `.claude/loop.md` | After a wait | The PR is merged or closed |
| Later: recurring work | Proactive | `/schedule` + `/goal` | On a schedule | You stop the routine. **Not in this setup yet.** |

Why this split:

- **A person at each written file.** The three files are cheap to change. Code is not. A mistake found in `PLAN.md` costs minutes.
- **`/goal` for building.** "Done" is clear and Claude can prove it: the criteria, the checks, and an open PR.
- **`/loop` for the PR.** CI and reviewers are outside Claude's control and take time. `/loop` waits between checks. `/goal` would start the next turn right away and use tokens while it waits.
- **The Stop hook stays on in both.** `/goal` is judged by a model that only reads the conversation. The Stop hook runs the real tests.

See [`examples/README.md`](examples/README.md) for the exact prompts, the `/goal` condition, and how the tools work together.

## Setup steps

Do these once for each project:

1. Write a short `CLAUDE.md`. Put in the build, test, lint, and typecheck commands, which work needs a change folder, the rules that matter, and the mistakes Claude keeps making. Keep it under one page. When Claude makes the same mistake twice, add a rule.
2. Add three hooks: one that formats each edited file (PostToolUse), one that blocks edits to old tests (PreToolUse), and one that runs the checks before Claude finishes (Stop).
3. Add `.claude/worktrees/`, `evals/results/`, and your screenshot folder to `.gitignore`. If your lint or test tools scan the whole repo, add the same folders and `evals/` to their ignore lists.
4. Run `/run-skill-generator` so Claude can start and use your app. It can take more than 10 minutes. Before you commit the skill it writes, remove paths and ports that work only on your machine, and make it save screenshots inside the project.
5. Add two subagents: `verify-app` (end-to-end test steps) and `reviewer`. Write `REVIEW.md` to say what the reviewer reports.
6. Write your team's rules as skills in `.claude/skills/`. For example: security rules for API code.
7. Turn on auto mode and `/sandbox`. On Linux, `/sandbox` needs `bubblewrap` and `socat`.
8. Collect real past tasks as evals (tests of your setup). Aim for 20–50 over time. Run them each time you change `CLAUDE.md`, a skill, a hook, or a subagent.

## For each change

1. Create a branch for the change from `main`.
2. Ask Claude to interview you and write `changes/<name>/INTENT.md`. Review it and commit it.
3. Ask Claude to write `SPEC.md` from `INTENT.md`. Review it with the checklist below, and commit it.
4. In a new session in plan mode, ask Claude to plan the change. Change the plan until a person who has not seen the conversation could build the change from it. When Claude asks "Would you like to proceed?", choose **Tell Claude what to change** and type "Save the plan as changes/<name>/PLAN.md and stop. Do not write any code." Both "Yes" options start coding at once. Review `PLAN.md` and commit it.
5. In a new session, run `/goal` with the condition from `examples/README.md`. Claude builds, checks, reviews, and opens a PR. If Claude saves screenshots outside the project, run `/add-dir <folder>` before `/goal`.
6. In another new session, run `/loop`. It follows `.claude/loop.md`: it fixes failed CI and review comments until the PR is merged.
7. Review the evidence and merge the PR. The loop sees the merge and stops.

Review checklist for `INTENT.md`, `SPEC.md`, and `PLAN.md`:

- Every answer you gave in the interview is in the file.
- The scope is what you asked for, and "Out of scope" lists what you do not want.
- Numbers, limits, and texts are right. Check a few facts against the code, such as file names and line numbers.
- Each acceptance criterion is something a test or a person can check.

## Measure it

The playbook lists numbers to track. These fit one repo:

- Time from an idea to a committed `INTENT.md`.
- First-pass CI success: the share of PRs whose first CI run passes.
- Rework: how many fix commits a PR needs after it opens.
- Bugs found before the merge, compared with bugs found after the merge.
- The eval pass count after each change to your setup. This one is this guide's addition.

Measure tokens from the session transcripts in `~/.claude/projects/`. In the field test, the number in the `/goal` status line was much lower than the transcript.

## Watch out

- **No check, no loop.** Without a real test, Claude "passes" by saying it is done.
- **A turn limit does not limit a build.** In the field test, a 37-minute build counted as one turn, so "stop after 30 turns" did nothing. Watch the time. Run `/goal` to see progress, and `/goal clear` to stop.
- **The `/goal` judge cannot see files.** It only reads the conversation. Ask Claude to print the evidence in its last message.
- **Claude cannot start `/verify` on its own.** Use the `verify-app` subagent inside `/goal` and `/loop`.
- **Some prompts wait for a person, even in auto mode.** "Do you trust this folder?" appears in a new folder. "Teach auto mode about your environment?" appears after the first auto mode turn. "Allow reads outside the working directories?" appears when Claude opens a file outside the project, such as a screenshot in `/tmp`. Answer them before you leave a run alone.
- **Do not press Enter on a suggested reply.** Claude Code sometimes puts a reply in the input box that you did not type. It can be wrong.
- **The test hook only covers file edit tools.** Claude could still change a test with a shell command, or change the hook script. `REVIEW.md` tells the reviewer to check for both.
- **The test hook can shape the design.** In the field test, an old test compared the whole stats response, so Claude added a new API route instead of new fields. If a spec changes an old contract on purpose, start Claude with `ALLOW_TEST_EDITS=1`.
- **`/code-review` does not read `REVIEW.md`.** Only the `reviewer` subagent and the managed Code Review service read it.
- **Add sessions only while you can review them.** The playbook suggests 2–3 sessions to start. The limit is how many PRs one person can review properly.
- **Keep approval prompts out of the build.** A hook that waits for a person belongs at a deploy gate. During the build, it makes Claude wait for you.
- **Cost adds up.** Anthropic's 3-agent test took 6 hours and $200. One agent took 20 minutes and $9, but its result was worse. In the field test, one feature took a 37-minute build with 454k output tokens, and the browser check (`verify-app`) used about half of that time. Each `/loop` check and each eval task also costs tokens.
- **A reviewer can push too hard.** If it reports style issues, Claude adds code it does not need. `REVIEW.md` limits nits to five.
- **Pushing a change to a CI workflow file needs the `workflow` scope** for `gh`. If `gh auth refresh -s workflow` does not add it, use an SSH remote.
- Boris does **not** skip permissions. He uses auto mode and pre-approved safe commands.

## Later: team and enterprise parts

The playbook also describes parts that need more than one repo. They are not in this setup yet.

- **Deploy gates.** A PreToolUse hook blocks a production deploy command until a person approves it. Claude may deploy freely to development, but not to production. First, make rollback one command that the team tests often in staging.
- **Claude in CI.** `claude -p` runs Claude once without a session, for example to explain a failed build. `claude-code-action` runs Claude in your own GitHub Actions.
- **Code Review service.** An admin turns it on for chosen GitHub repos. It reviews every PR and reads `REVIEW.md`. It is a research preview for Team and Enterprise plans.
- **Maintain stage.** A script watches production numbers. When a number leaves its normal range, the script starts Claude. Claude writes its diagnosis as an `INTENT.md`, so the problem goes through the same steps.
- **Claude Tag.** Claude joins a Slack channel and responds first to incidents. A small fix becomes a PR. Larger work becomes an `INTENT.md`.
- **Claude Security.** Scheduled security scans of connected repos. Claude checks each finding before it reports it.
- **Managed settings.** An organization sets rules that no one can override on their own machine: blocked files and commands, the sandbox, and approved hooks and plugins only.
- **One source of truth.** If Jira or another tool already tracks requirements, choose the main record: the repo files, the other tool, or both with links to each other.

## Files

- [`examples/`](examples/): example `CLAUDE.md`, `REVIEW.md`, change templates, `loop.md`, hooks, subagents, a skill, and an eval runner to copy into a project
- [`docs/summary.html`](docs/summary.html): the one-page visual summary
- [`docs/sources.md`](docs/sources.md): where each claim comes from
- [`docs/open-questions.md`](docs/open-questions.md): things to check and improve
- [`docs/field-tests/`](docs/field-tests/): reports from tests of this guide on real projects

## Status

Third draft, 14 Sep 2026. Tested once on a real project, and the fixes from that test are applied. See `docs/field-tests/2026-09-13-shelf.md`.
