---
name: api-security
description: The team's security rules for HTTP API code. Use when you write or review a spec, a plan, or code that adds or changes an API route, login, permissions, or logging.
---

<!--
Example of team knowledge written as a skill. Replace these rules with your own.
When a rule changes, change this file. Everyone who pulls the repo receives the new version.
-->

# API security rules

- Every new route checks that the user is logged in and is allowed to do the action. Return 401 when the user is not logged in. Return 403 when the user is not allowed.
- Check every input against a schema before you use it. Return 400 with a clear message for bad input.
- Limit every database query to the data of the caller's account.
- Never write passwords, tokens, email addresses, or request bodies to logs.
- Read secrets from environment variables. Never commit them.

How to use these rules:

- In `SPEC.md`: add an acceptance criterion for each rule that applies to the change.
- In a review: report a broken rule as Important.
