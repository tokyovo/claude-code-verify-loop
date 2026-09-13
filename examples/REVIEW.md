# Review instructions

<!--
Example. Two reviewers read this file:
- the `reviewer` subagent in .claude/agents/reviewer.md, before the PR opens
- Code Review, the managed GitHub service, if your organization turns it on
The local /code-review command does not read this file.
Keep it short. A long file weakens the rules that matter most.
-->

## Passes

Check the change three times. Tag each finding with its pass:

- Bugs: wrong logic, broken edge cases, broken existing behavior.
- Security: injection, missing auth checks, secrets or personal data in logs.
- Spec: the change does what SPEC.md and PLAN.md say, and nothing more.

## What Important means here

A finding is Important only if it breaks behavior, leaks data, or breaks a rule in a project skill. Everything else is a Nit: style, naming, and "could be cleaner".

## Limit the nits

Report at most five Nits. Give the rest as a count.

## Do not report

- Anything CI already checks: lint, formatting, and type errors.
- Generated files and any lock file. Example: files under `generated/`. Change this line to your project's folders.

## Always check

- No test that existed before this branch was changed, unless SPEC.md says the old behavior was wrong.
- No file under `.claude/hooks/` was changed, unless SPEC.md asks for it.
- Each acceptance criterion in SPEC.md has a test or an app check.
