# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A written guide, not an app. It explains how to set up a "verify loop" in Claude Code: Claude plans, builds, runs a pass/fail check, fixes its own mistakes, and opens a PR. It maps this loop onto the six stages of Anthropic's AI-native SDLC playbook. There is no build, no package manager, and no test suite.

- `README.md`: the guide itself.
- `docs/summary.html`: a one-page visual version of the README.
- `docs/sources.md`: the source for each claim.
- `docs/open-questions.md`: things not yet checked or tested.
- `docs/field-tests/`: reports from tests of the guide on real projects. `docs/field-tests/tools/drive.sh` drives a live Claude Code session in tmux for these tests.
- `examples/`: files a reader copies into their own project.

## `examples/` is a template, not config for this repo

- `examples/CLAUDE.md` and `examples/REVIEW.md` are samples for other projects. Do not treat their rules or `npm` commands as rules for this repo.
- `examples/.claude/` (hooks, subagents, skills, settings) is not active here. Claude Code only loads `.claude/` from the project root.

## Checks

The runnable code is the three hook scripts, the eval runner, the example eval check, the field test driver, and the settings file. After editing them, run:

```bash
for f in examples/.claude/hooks/*.sh examples/evals/run-evals.sh examples/evals/tasks/_example/check.sh docs/field-tests/tools/drive.sh; do bash -n "$f" || echo "syntax error: $f"; done
jq empty examples/.claude/settings.json      # valid JSON
```

`bash -n` checks only its first file argument, so check each file on its own.

To test the Stop hook, use a scratch git repo and a scratch `TMPDIR` (the hook keeps its state there). It reads JSON on stdin. Test at least these cases:

```bash
run() { printf '{"session_id":"%s"}' "$1" | TMPDIR=/path/to/state CLAUDE_PROJECT_DIR=/path/to/scratch VERIFY_CMD="$2" examples/.claude/hooks/stop-verify.sh; echo $?; }
# clean main, VERIFY_CMD=false                         → 0 (nothing changed)
# uncommitted code change, VERIFY_CMD=false            → 2
# same change, VERIFY_CMD=true, then commit it, false  → 0 (content already passed)
# committed code on a branch, new session, false       → 2 (compared with the base branch)
# only changes/**/*.md on a branch, new session, false → 0 (documents only)
```

To test the test protection hook, use a scratch repo with a committed `tests/old.test.ts` on `main`, and a feature branch checked out:

```bash
echo '{"tool_input":{"file_path":"/path/to/scratch/tests/old.test.ts"}}' | CLAUDE_PROJECT_DIR=/path/to/scratch examples/.claude/hooks/protect-tests.sh; echo $?   # expect 2
echo '{"tool_input":{"file_path":"/path/to/scratch/tests/new.test.ts"}}' | CLAUDE_PROJECT_DIR=/path/to/scratch examples/.claude/hooks/protect-tests.sh; echo $?   # expect 0
```

To test the eval runner without spending tokens, set `CLAUDE_BIN` to a stub script in a scratch repo. Check that the prompt starts with `EVAL_NOTE`, that git is clean when the stub starts, and that branches the stub creates are deleted.

All hooks need `jq`.

## Keep files in sync

The same facts appear in several places. When you change one, update the others.

- **The six stages, the eight parts, the setup steps, the steps for each change, and the warnings** are in both `README.md` and `docs/summary.html`.
- **The check command** (`npm run lint && npm run typecheck && npm test`) is in `examples/CLAUDE.md`, `examples/changes/_template/SPEC.md`, `examples/.claude/loop.md`, `VERIFY_CMD` in `stop-verify.sh`, `permissions.allow` in `settings.json`, and both `/goal` conditions in `examples/README.md`.
- **The `gh` commands** in `examples/.claude/loop.md` that run without a prompt are listed in `permissions.allow` in `settings.json`.
- **The subagent names** `verify-app` and `reviewer`, and their output formats (`RESULT: PASS | FAIL | BLOCKED`, `VERDICT: APPROVE | CHANGES NEEDED`), are used in `examples/CLAUDE.md`, `examples/changes/_template/SPEC.md`, and the `/goal` conditions in `examples/README.md`.
- **The review rules** (Important vs Nit, at most five nits, no old test changed) are in `examples/REVIEW.md` and `reviewer.md`.
- **The change folder** `changes/<name>/` with `INTENT.md`, `SPEC.md`, and `PLAN.md` is used in `README.md`, `docs/summary.html`, `examples/README.md`, `examples/CLAUDE.md`, the templates, `loop.md`, `reviewer.md`, and `verify-app.md`.
- **Which work needs a change folder** (new behavior yes, bug fix no, evals no) is in `README.md`, `docs/summary.html`, `examples/CLAUDE.md`, and `EVAL_NOTE` in `run-evals.sh`.
- **The loop stages** (branch → `INTENT.md` → `SPEC.md` → `PLAN.md` → `/goal` → `/loop`) and the setup steps are in `README.md`, `examples/README.md`, and `docs/summary.html`.
- **The plan approval choice** ("Tell Claude what to change", then "Save the plan as changes/<name>/PLAN.md and stop. Do not write any code.") is in `README.md`, `docs/summary.html`, `examples/README.md`, and `examples/changes/_template/PLAN.md`.
- **The `.gitignore` lines** (`.claude/worktrees/`, `evals/results/`, the screenshot folder) are in `README.md`, `docs/summary.html`, and `examples/README.md`.
- **The hook behavior** is described in `examples/README.md`. Stop hook: a content fingerprint of the working tree; skip when it matches the last pass or when only `DOCS_PATTERN` files changed; compare with the base branch before the first pass; exit code 2 blocks; `MAX_BLOCKS` default 5; last 40 lines of output. Test protection hook: blocks tests that exist on `BASE_REF`, allows new test files, `ALLOW_TEST_EDITS=1` turns it off.
- **The eval runner behavior** (setup commit, `EVAL_NOTE`, branch cleanup) is in the script header and `examples/evals/README.md`.
- **The file tree** in `examples/README.md` must match the real files.
- **Measured numbers** from a field test (for example, 37 minutes, 454k output tokens) must match the report in `docs/field-tests/`.

## Claims and sources

- Every new claim about Claude Code features, or quote from Boris Cherny or Anthropic, needs a row in `docs/sources.md`.
- A claim that comes from a field test names the report and the Claude Code version.
- If a claim is not confirmed, put it under "Not fully confirmed" in `sources.md`, or add it to `docs/open-questions.md`.
- Say when a number is an estimate, or comes from one run, not a measured average (for example, the "2–3 times better" figure).
- Say when a choice is this guide's own and not from a source (for example, the `changes/<name>/` folder).
- When you resolve an open question, tick its box in `docs/open-questions.md` and fix the guide text.

## Writing style

The guide uses plain English: short sentences, active voice, no idioms, and each technical term explained the first time. Match this in every file, including the example files.
