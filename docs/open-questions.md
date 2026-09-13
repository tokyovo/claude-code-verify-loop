# Open questions

Things to check and improve in the guide.

## To verify

- [ ] `/run-skill-generator` and `/verify` do not show in Claude's skill list on version 2.1.270. For `/verify`, the likely reason: it has `disable-model-invocation: true`, so only you can type it. Check that `/run-skill-generator` works when typed.
- [ ] Confirm the GitHub app install command (`/install-github-app` or `/install-github-action`).
- [x] Confirm `/goal` syntax and turn limit on the current version. Syntax: `/goal <condition>`. The turn limit is a clause in the condition, judged by a model. It is not enforced.
- [ ] Read the playbook page directly. Check the items listed under "Not fully confirmed" in `sources.md`.
- [ ] Check that `claude -p --permission-mode auto` runs an eval task with no permission prompts.
- [ ] Check that `ALLOW_TEST_EDITS=1`, set when Claude starts, reaches the PreToolUse hook.
- [ ] Check that Claude can save `PLAN.md` right after you approve a plan in plan mode.

## To test on a real project

- [ ] Pick one small repo. Apply the setup steps.
- [ ] Give Claude one change request only. Record: turns used, time, cost, and whether the PR was correct.
- [ ] Compare: with and without the Stop hook or `/goal`.
- [ ] Compare: with and without the reviewer subagent.
- [ ] Compare: `INTENT.md` + `SPEC.md` + `PLAN.md`, against `SPEC.md` alone. Record rework commits after the PR opens.
- [ ] Check that `/goal` really stops near "stop after 30 turns".
- [ ] Check that `/loop` with `loop.md` stops on its own after the PR is merged.
- [ ] Record the token cost of `/loop` while the PR is quiet.
- [ ] Check that `protect-tests.sh` blocks a real edit to an old test, and allows a new test file.
- [ ] Run `evals/run-evals.sh` with 3 real tasks. Record time, cost, and whether the results repeat.

## To add

- [x] Example `CLAUDE.md`
- [x] Example Stop hook script
- [x] Example `verify-app` and reviewer subagent files
- [x] Example `SPEC.md` template
- [x] Example `loop.md`
- [x] Example `INTENT.md` and `PLAN.md` templates
- [x] Example `REVIEW.md`, skill, test protection hook, and eval runner
- [ ] Stop hook and `/goal` together. Known: all Stop hooks run in parallel, and either one can keep Claude working. Not known: do blocks from both count together toward the 8-block limit?
- [ ] Check the Stop hook JSON option (`"decision": "block"`) and `stop_hook_active`. The examples use exit code 2, which the docs confirm.
- [ ] A deploy gate hook example (stage 5 of the playbook).
- [ ] A stage 6 example: a scheduled or alert-started run that writes `INTENT.md`.
