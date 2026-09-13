# CLAUDE.md

<!--
Example. Replace the commands with your project's real ones.
Keep this file under one page. Claude reads all of it at the start of every session.
-->

## Commands

- Install: `npm install`
- Start the app: `npm run dev` (runs on http://localhost:3000)
- Lint: `npm run lint`
- Typecheck: `npm run typecheck`
- Test: `npm test`
- One test file: `npm test -- path/to/file.test.ts`

## Files for each change

Each change has a folder `changes/<name>/`. A person reviews and commits each file before the next step starts.

1. `INTENT.md`: the problem and the outcome.
2. `SPEC.md`: the acceptance criteria.
3. `PLAN.md`: the files that change, the order of work, the risks, and the proof.

Templates are in `changes/_template/`.

## How to build a change

1. Read `SPEC.md` and `PLAN.md` for the change. If one is missing or unclear, ask before you write code.
2. Write a failing test for each acceptance criterion first. Put new tests in new test files.
3. Follow the order of work in `PLAN.md`. Write the code until the tests pass.
4. Run lint, typecheck, and tests. Show the command and its output.
5. Use the `verify-app` subagent to check the change in the running app.
6. Use the `reviewer` subagent on the diff. Fix every Important finding.
7. Open a PR. In the description, link the change folder and paste the evidence from steps 4–6.

## Rules

- Never say a task is done without showing passing output.
- Do not change a test that existed before this branch. A hook blocks it. If `SPEC.md` says the old behavior was wrong, ask a person.
- Never push to `main`. Work on a branch.
- Never edit files in `generated/`.

## Mistakes to avoid

<!-- When Claude makes the same mistake twice, add one line here. Example: -->
- The test database is reset by `npm test`. Do not run tests against the dev database.
