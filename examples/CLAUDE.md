# CLAUDE.md

<!-- Example. Replace the commands with your project's real ones. Keep this file short. -->

## Commands

- Install: `npm install`
- Start the app: `npm run dev` (runs on http://localhost:3000)
- Lint: `npm run lint`
- Typecheck: `npm run typecheck`
- Test: `npm test`
- One test file: `npm test -- path/to/file.test.ts`

## How to work on a feature

1. Read `SPEC.md`. If it is missing or unclear, ask before you write code.
2. Write a failing test for each acceptance criterion first.
3. Write the code until the tests pass.
4. Run lint, typecheck, and tests. Show the command and its output.
5. Use the `verify-app` subagent to check the change in the running app.
6. Use the `reviewer` subagent on the diff. Fix every real problem it reports.
7. Open a PR. In the description, paste the evidence from steps 4–6.

## Rules

- Never say a task is done without showing passing output.
- Do not change a test to make it pass unless the spec says the old behavior was wrong.
- Never push to `main`. Work on a branch.
- Never edit files in `generated/`.

## Mistakes to avoid

<!-- Add one line here each time Claude makes a mistake. Example: -->
- The test database is reset by `npm test`. Do not run tests against the dev database.
