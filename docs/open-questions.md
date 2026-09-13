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

- [ ] Example `CLAUDE.md`
- [ ] Example Stop hook script
- [ ] Example `verify-app` and reviewer subagent files
- [ ] Example `SPEC.md` template
