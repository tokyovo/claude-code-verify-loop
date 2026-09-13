# Look after this branch's pull request

<!--
Example. Bare `/loop` runs this file instead of its built-in prompt.
The built-in prompt also runs cleanup passes (bug hunts, simplification). This file does not,
so the loop never adds changes that a reviewer did not ask for.
Change the check command to match your project.
-->

Each time this runs:

1. Find the PR for the current branch: `gh pr view --json number,state,url`.
   - If there is no PR, say so in one line and stop the loop.
   - If the PR is merged or closed, say so in one line and stop the loop.
2. Check CI: `gh pr checks`.
   - If a check failed, read its log with `gh run view <run-id> --log-failed`. Find the cause. Make the smallest fix.
3. Read new review comments: `gh pr view --comments`, and `gh api repos/{owner}/{repo}/pulls/<number>/comments` for comments on lines of code.
   - Fix each comment that points to a real problem.
   - If you disagree with a comment, do not change the code and do not reply on GitHub. List it in your message with your reason, so a person can decide.
4. If you changed code, run `npm run lint && npm run typecheck && npm test` and show the output. Commit and push only if it passes.
5. If CI is green and there are no new comments, say "PR is quiet" in one line and wait longer before the next check.

Rules:

- Work only on this PR. Do not start new features, refactors, or cleanups.
- Fix the code, not the tests. Do not change a test that existed before this branch.
- If a comment asks for a change that `changes/<name>/SPEC.md` does not cover, do not make it. List it for a person.
- Never push to `main`. Never force-push.
- Do not merge the PR. A person merges it.
- If the same CI failure comes back after 3 fixes, stop the loop and explain what you tried.
