# PLAN: <change name>

<!--
Template for stage 3 (Build). Start a new session in plan mode:
  claude --permission-mode plan
  > Read changes/<name>/SPEC.md. Interview me about anything the spec leaves open. Then write a plan with the sections in changes/_template/PLAN.md.
Change the plan until a person who has not seen the conversation could build the change from the plan alone.
When Claude asks "Would you like to proceed?", do not choose a "Yes" option. Both start coding in this session.
Choose "Tell Claude what to change" and type:
  Save the plan as changes/<name>/PLAN.md and stop. Do not write any code.
Plan mode also keeps a copy in ~/.claude/plans/. The file in the repo is the one that counts. Commit it.
-->

- Spec: [SPEC.md](SPEC.md)

## Files that change

- `<path>` — <what changes, and why>

## Order of work

1. <A step. Each step ends with a check that passes.>

## Risks

- <What could break, and how this plan prevents it>

## Proof

- <Each acceptance criterion, and the test or app check that proves it>
