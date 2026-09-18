# Open questions

Things to check and improve in the guide.

## To verify

- [x] `/run-skill-generator` works when typed. Field test: it ran for 12.5 minutes and wrote a run skill. `/verify` is still not in Claude's skill list, because it has `disable-model-invocation: true`.
- [ ] Confirm the GitHub app install command (`/install-github-app` or `/install-github-action`).
- [x] Confirm `/goal` syntax and turn limit on the current version. Syntax: `/goal <condition>`. The turn limit is a clause in the condition, judged by a model. It is not enforced.
- [ ] Read the playbook page directly. Check the items listed under "Not fully confirmed" in `sources.md`.
- [x] Check that `claude -p --permission-mode auto` runs an eval task with no permission prompts. Field test: both eval tasks ran with no prompt.
- [ ] Check that `ALLOW_TEST_EDITS=1`, set when Claude starts, reaches the PreToolUse hook.
- [x] Check that Claude can save `PLAN.md` right after you approve a plan in plan mode. Field test: choose "Tell Claude what to change" and ask Claude to save the plan and stop. The "Yes" options start coding.
- [ ] Why did `gh auth refresh -h github.com -s workflow` not add the `workflow` scope in the field test?
- [ ] What does the token number in the `/goal` status line count? In the field test, it was about one third of the output tokens in the transcript.
- [ ] Test `/sandbox` on Linux with `bubblewrap` and `socat` installed.

## To test on a real project

- [x] Pick one small repo. Apply the setup steps. Done on `shelf`, see `docs/field-tests/2026-09-13-shelf.md`.
- [x] Give Claude one change request only. Record: turns used, time, cost, and whether the PR was correct. Done in the field test.
- [ ] Compare: with and without the Stop hook or `/goal`.
- [ ] Compare: with and without the reviewer subagent.
- [ ] Compare: `INTENT.md` + `SPEC.md` + `PLAN.md`, against `SPEC.md` alone. Record rework commits after the PR opens.
- [x] Check that `/goal` really stops near "stop after 30 turns". Field test: no. A 37-minute build counted as one turn. The guide no longer suggests a turn limit.
- [x] Check that `/loop` with `loop.md` stops on its own after the PR is merged. Field test: yes, on the first check after the merge.
- [x] Record the token cost of `/loop` while the PR is quiet. Field test: the check after the merge took 23 s. Three checks over 66 minutes used 51k output tokens and 5.8M cache-read tokens.
- [x] Check that `protect-tests.sh` blocks a real edit to an old test, and allows a new test file. Field test: blocked in a live session. The build added 4 new test files with no block.
- [ ] Run `evals/run-evals.sh` with 3 real tasks. Record time, cost, and whether the results repeat. So far: 2 tasks, run three times. `search-case` passed all 3 times. `pages-limit` failed with the old runner and passed both times with the new one.
- [x] Run the new Stop hook (content fingerprint) in a live session. Done on 18 Sep 2026: it blocked committed code that failed lint, and it skipped document-only changes. See `docs/field-tests/2026-09-18-shelf-hook-and-evals.md`.
- [x] Run the new eval runner (`EVAL_NOTE`, setup commit, branch cleanup) with real Claude. Done on 18 Sep 2026: 2 of 2 passed, no branches left.
- [x] Run the eval runner with its `.gitignore` fix and real Claude. Check that the Stop hook runs the checks only when the code changed. Done on 18 Sep 2026: one check run per task, and the run took 269 s instead of 416 s.
- [x] Run a bug fix with the short `/goal` condition in `examples/README.md`. Done on 18 Sep 2026: PR #2 on shelf in 5.5 minutes.

## To add

- [x] Example `CLAUDE.md`
- [x] Example Stop hook script
- [x] Example `verify-app` and reviewer subagent files
- [x] Example `SPEC.md` template
- [x] Example `loop.md`
- [x] Example `INTENT.md` and `PLAN.md` templates
- [x] Example `REVIEW.md`, skill, test protection hook, and eval runner
- [ ] Stop hook and `/goal` together. Known: all Stop hooks run in parallel, and either one can keep Claude working. The field test showed both hooks in the same stop. Not known: do blocks from both count together toward the 8-block limit?
- [ ] Check the Stop hook JSON option (`"decision": "block"`) and `stop_hook_active`. The examples use exit code 2, which the docs confirm.
- [ ] A deploy gate hook example (stage 5 of the playbook).
- [ ] A stage 6 example: a scheduled or alert-started run that writes `INTENT.md`.
