# CLAUDE.md

<!--
Example. Replace the commands with your project's real ones.
Delete every line that does not fit your project, including the lines marked "Example".
Keep this file under one page. Claude reads all of it at the start of every session.
-->

## Commands

- Install: `npm ci`
- Start the app: `npm run dev` (runs on http://localhost:3000; if that port is taken: `PORT=3100 npm run dev`)
- Lint: `npm run lint`
- Typecheck: `npm run typecheck`
- Test: `npm test`
- One test file: `npm test -- path/to/file.test.ts`

## Which work needs a change folder

- **New behavior** (a new feature, or a change to how the app works): it needs a folder `changes/<name>/` with `INTENT.md`, `SPEC.md`, and `PLAN.md`. A person reviews and commits each file before the next step starts. If a file is missing, write a draft, ask, and stop. Do not write code.
- **A bug fix** (the app does not do what it already should): no change folder. Write a failing test that shows the bug, then fix the code.
- If the prompt says that no change folder is needed, follow the prompt.

Templates are in `changes/_template/`.

## How to build a change

1. Read `SPEC.md` and `PLAN.md` for the change. If one is unclear, ask before you write code.
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
- Save screenshots and other check output inside the project, in a folder that `.gitignore` lists.
- Example: Never edit files in `generated/`.

## Mistakes to avoid

<!-- When Claude makes the same mistake twice, add one line here. Example: -->
- Example: The test database is reset by `npm test`. Do not run tests against the dev database.
