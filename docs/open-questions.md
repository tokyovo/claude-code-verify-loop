# Open questions

Things to check and improve in the guide.

## To verify

- [ ] `/run-skill-generator` and `/verify` do not show in Claude's skill list on version 2.1.270. Check if they appear when typed, or if an update is needed.
- [ ] Confirm the GitHub app install command (`/install-github-app` or `/install-github-action`).
- [ ] Confirm `/goal` syntax and turn limit on the current version.

## To test on a real project

- [ ] Pick one small repo. Apply the 7 setup steps.
- [ ] Give Claude one feature request only. Record: turns used, time, cost, and whether the PR was correct.
- [ ] Compare: with and without the Stop hook or `/goal`.
- [ ] Compare: with and without the reviewer subagent.

## To add

- [x] Example `CLAUDE.md`
- [x] Example Stop hook script
- [x] Example `verify-app` and reviewer subagent files
- [x] Example `SPEC.md` template
- [ ] Check if a Stop hook and `/goal` together cause double blocking. Pick one if so.
- [ ] Check the Stop hook JSON option (`"decision": "block"`) and `stop_hook_active`. The examples use exit code 2, which the docs confirm.
