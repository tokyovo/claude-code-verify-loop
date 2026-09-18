# Field test: new Stop hook and eval runner on shelf

A follow-up to [`2026-09-13-shelf.md`](2026-09-13-shelf.md). It tests the two scripts that were changed after that test. Before this run, both were tested only in scratch repos.

- Date: 18 Sep 2026
- Claude Code version: 2.1.270, model Opus 5
- Guide version: commit `a11b698`
- Test project: `shelf` at commit `6bc2521` (the new setup files copied from the guide)

## Setup changes on shelf

- Copied the new `stop-verify.sh`, `run-evals.sh`, `loop.md`, and `evals/README.md`.
- Added "Which work needs a change folder" to `CLAUDE.md`.
- Added `.claude/worktrees/` and `.shelf-run/` to `.gitignore`, and `.claude/worktrees/`, `evals/`, and `.shelf-run/` to the ESLint ignore list.
- Changed the run skill to save screenshots in `.shelf-run/` inside the project, not in `/tmp`.
- Lint, typecheck, and all 144 tests passed.

## Test 1: Stop hook in a live session

A new session in auto mode, on a branch `hook-test` from `main`. The tester gave two requests.

| Stop | Situation | Hook result |
|---|---|---|
| 1 | Claude added `const unusedForHookTest = 1;`, **committed it**, and did not run the checks | **Blocked:** "Checks failed (attempt 1 of 5)", with the ESLint error |
| 2 | Claude removed the line, ran the checks itself, and committed the removal | Skipped in 77 ms. The code was the same as `main` again, so nothing needed checking. |
| 3 | Claude committed only `changes/hook-note/INTENT.md` | Skipped in 107 ms (documents only) |

- Stop 1 is the case that failed in the first field test: the old hook skipped the checks because git was clean after a commit. The new hook compared the files with the base branch and ran the checks.
- After the block, Claude followed the hook's message: it fixed the cause, ran the checks, and showed the passing output. It did not rewrite the test commit.
- The Claude Code transcript records a block as a hook error with the hook's message. Its `preventedContinuation` field was `false` for all three stops.
- The hook kept its state in `/tmp/claude-stop-verify-<session>.passed`: one tree hash.
- The input box again showed a suggested reply that the tester had not typed ("reset the branch to 99ff688 and test again").

## Test 2: eval runner

`SETUP_CMD="npm ci" evals/run-evals.sh`, the same two tasks as the first field test, with real Claude.

| | First field test (old runner) | This test (new runner) |
|---|---|---|
| Result | 1 of 2 passed | **2 of 2 passed** |
| `pages-limit` | FAIL: Claude wrote spec drafts and asked questions | PASS: Claude coded the limit. Hidden test 3 of 3, all 69 tests pass |
| `search-case` | PASS | PASS: hidden test 3 of 3, all 67 tests pass |
| Time for both tasks | 464 s | 416 s |
| Output tokens, main session + subagents | 43k (`search-case`) and 65k (`pages-limit`) | 25k (`search-case`) and 21k (`pages-limit`) |
| Branches left after the run | 2 | 0 |
| Worktrees left after the run | 0 | 0 |

- **`EVAL_NOTE` worked.** Both prompts started with the note. `pages-limit` went straight to code, and it passed. The "spec first" rule in `CLAUDE.md` did not stop it.
- **The setup commit worked.** Git was clean when Claude started. No task said "do not commit the untracked setup files", as the first test did.
- **Branch cleanup was not needed.** Claude created no branch, because `EVAL_NOTE` told it to stay on the detached HEAD. The only branches after the run were `main` and the `fix-tag-pattern` branch that existed before it.
- **Both tasks ran the full loop:** a test first, the fix, the check command, then `verify-app` and `reviewer` as background subagents.

### A new problem: the Stop hook ran the checks at almost every stop

In each task, the main session stopped 5 times: 4 stops while its subagents ran in the background, and one at the end. The Stop hook ran the full checks at the first 4 stops, about 15 s each. The last stop skipped in 85–88 ms.

| Task | Stops (time, hook duration) | Subagents |
|---|---|---|
| `search-case` | 01:17:15 (17.2 s), 01:17:45 (15.1 s), 01:18:02 (15.2 s), 01:18:50 (15.2 s), 01:18:52 (85 ms) | 01:16:53–01:18:31 and 01:16:56–01:17:34 |
| `pages-limit` | 01:20:20 (14.3 s), 01:21:00 (15.4 s), 01:21:18 (17.1 s), 01:22:34 (15.1 s), 01:22:35 (88 ms) | 01:20:03–01:22:13 and 01:20:05–01:20:49 |

- The cause: `verify-app` wrote screenshots to `.shelf-run/` and browser state to `.gstack/`. The eval worktree is at the old `base` commit, and its `.gitignore` did not list either folder. So each new screenshot changed the hook's fingerprint, and the hook ran the checks again.
- The cost: about 1 minute of each 3.5-minute task.
- The fix, applied to `run-evals.sh`: add the current `.gitignore` lines to the worktree before the setup commit. A stub test confirmed it: after the stub wrote files to `.shelf-run/` and `.gstack/`, `git status` in the eval worktree was still clean. Test 4 confirms it with real Claude.
- In a normal session, the project's own `.gitignore` lists the screenshot folder. That is why the setup steps say to add it.

## Test 3: a bug fix with the short `/goal` condition

The real page bug from the first field test: the tag input's `pattern="[A-Za-z0-9-]+"` is not valid for Chrome. The tester created the branch `fix-tag-pattern` from `main`, started a new session in auto mode, and sent the bug-fix `/goal` condition from `examples/README.md`, with the bug described in two sentences. No change folder.

- **Result: `✔ Goal achieved (5m · 1 turn · 32.2k tokens)`**, 11:23 to 11:29. PR #2 "Escape the hyphen in the tag input pattern": 3 files, +29 / −2. CI passed in 25 s.
- Claude followed the bug-fix rule in `CLAUDE.md`: no change folder, a failing test first (`tests/tag-input-pattern.test.ts`, which compiles the pattern with the `v` flag as Chrome does), then the fix. All 146 tests passed. No old test changed.
- `verify-app` checked the page in headless Chrome: no console error, bad tags such as `sci fi` are now blocked in the browser, and good tags still save. It also confirmed that `main` still shows the old error.
- **Claude corrected the person's bug report.** The prompt said that the error appears on every page load. Claude found that Chrome logs it only when it first checks a tag value, and wrote the correct behavior in the commit and the PR.
- Claude removed the note in the run skill that listed this error as expected. Without that change, the note would tell later agents to ignore a real error.
- The reviewer approved with one Nit: the browser now blocks a tag with a space before or after it, which the server used to trim. Claude described it in the PR and did not change it.
- Main session: 49 assistant messages, 22k output tokens, 3.0M cache-read tokens.

Stop hook runs in this session:

| Stop | Hook duration | What happened |
|---|---|---|
| 01:24:48 | 12.9 s | Ran the checks: the committed fix differed from `main` |
| 01:25:04, 01:25:07, 01:28:04 | 82, 55, 46 ms | Skipped: no code change since the pass, or only a Markdown file changed |
| 01:29:00 | 60 ms, plus 8.5 s for the `/goal` condition | Skipped, and the `/goal` judge confirmed the goal |

The checks ran once, when they were needed. shelf's own `.gitignore` lists `.shelf-run/`, so screenshots did not make the hook run again, unlike in the eval worktrees.

The input box showed a suggested reply once more ("open the PR once verify-app finishes"). PR #2 is left open for a person to merge.

## Test 4: eval runner with the `.gitignore` fix

The runner from guide commit `96b2865`, copied to shelf as `e9e019d`. The same two tasks and command as Test 2.

| | Test 2 (before the fix) | Test 4 (after the fix) |
|---|---|---|
| Result | 2 of 2 passed | 2 of 2 passed |
| Time for both tasks | 416 s | 269 s |
| `pages-limit` Stop hook runs | 5 stops: 4 check runs of 14–17 s, then a skip | 1 stop: 1 check run of 3.7 s |
| `search-case` Stop hook runs | 5 stops: 4 check runs of 15–17 s, then a skip | 5 stops: 1 check run of 4.0 s, then 4 skips of 14–55 ms |
| Output tokens, main session + subagents | 25k and 21k | 22k (`search-case`) and 22k (`pages-limit`) |
| Branches and worktrees left | none | none |

- **The fix worked.** The Stop hook ran the checks once in each task, when the code had changed. Screenshots and browser logs no longer counted as changes.
- Each check run was also faster: about 4 s instead of 15 s. This report does not know why. One possible cause is less load on the machine, because the browser check no longer ran at the same time as the checks.
- In `pages-limit`, the main session stopped only once. In Test 2 it stopped 5 times. The number of stops depends on how Claude waits for its subagents, and it can change from run to run.

## Summary

- **The new Stop hook works in live sessions.** It blocked committed code that failed lint, which the old hook let through. It skipped document-only changes and unchanged content in 46–107 ms.
- **The new eval runner works.** Both tasks passed, including the one that failed before. No branches were left behind.
- **One new problem, fixed:** in eval worktrees, check output was not ignored, so the hook ran the checks at almost every stop. `run-evals.sh` now adds the current `.gitignore` lines. With real Claude, the hook then ran the checks once per task, and the eval run took 269 s instead of 416 s.
- **The bug-fix flow works.** One sentence of context and a short `/goal` condition gave a correct, tested PR in 5.5 minutes.
