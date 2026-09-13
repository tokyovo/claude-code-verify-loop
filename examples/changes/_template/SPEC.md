# SPEC: <change name>

<!--
Template for stage 2 (Design). Claude writes this file from the accepted INTENT.md. Start Claude and say:
"Read changes/<name>/INTENT.md. Write changes/<name>/SPEC.md from the template. Follow the project skills that apply. Ask me when INTENT.md does not answer a question."
Check that the spec solves the problem in INTENT.md. Then commit it.
-->

- Intent: [INTENT.md](INTENT.md)

## Goal

<One or two sentences. What the user can do after this change, and why.>

## Acceptance criteria

Each line must be something a person or a test can check as pass or fail.

- [ ] <Example: On /settings, a user can change their display name and see it saved after reload.>
- [ ] <Example: A name longer than 50 characters shows the error "Name must be 50 characters or less".>
- [ ] <Example: The API returns 401 when the user is not logged in.>

## Out of scope

- <Things this change must NOT do.>

## Edge cases

- <Empty input, wrong input, slow network, no permission, ...>

## Open questions from INTENT.md

- <Question> — <the answer, or "carried forward" and the reason>

## How to verify

- Automated: `npm run lint && npm run typecheck && npm test` all pass.
- In the app: the `verify-app` subagent checks every acceptance criterion and gives evidence.
- Review: the `reviewer` subagent returns `VERDICT: APPROVE`.

## Done means

All boxes above are checked, with evidence in the PR description.
