# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A written guide, not an app. It explains how to set up a "verify loop" in Claude Code: Claude plans, builds, runs a pass/fail check, fixes its own mistakes, and opens a PR. There is no build, no package manager, and no test suite.

- `README.md`: the guide itself.
- `docs/summary.html`: a one-page visual version of the README.
- `docs/sources.md`: the source for each claim.
- `docs/open-questions.md`: things not yet checked or tested.
- `examples/`: files a reader copies into their own project.

## `examples/` is a template, not config for this repo

- `examples/CLAUDE.md` is a sample for other projects. Do not treat its rules or `npm` commands as rules for this repo.
- `examples/.claude/` (hooks, subagents, settings) is not active here. Claude Code only loads `.claude/` from the project root.

## Checks

The only runnable code is the two hook scripts and the settings file. After editing them, run:

```bash
bash -n examples/.claude/hooks/*.sh          # shell syntax
jq empty examples/.claude/settings.json      # valid JSON
```

To test the Stop hook for real, run it against a scratch git repo that has an uncommitted file. It reads JSON on stdin:

```bash
echo '{"session_id":"t"}' | CLAUDE_PROJECT_DIR=/path/to/scratch VERIFY_CMD=false examples/.claude/hooks/stop-verify.sh; echo $?   # expect 2
echo '{"session_id":"t"}' | CLAUDE_PROJECT_DIR=/path/to/scratch VERIFY_CMD=true  examples/.claude/hooks/stop-verify.sh; echo $?   # expect 0
```

Both hooks need `jq`.

## Keep files in sync

The same facts appear in several places. When you change one, update the others.

- **The six parts, setup steps, and warnings** are in both `README.md` and `docs/summary.html`.
- **The check command** (`npm run lint && npm run typecheck && npm test`) is in `examples/CLAUDE.md`, `examples/SPEC.md`, `examples/.claude/loop.md`, `VERIFY_CMD` in `stop-verify.sh`, and `permissions.allow` in `settings.json`.
- **The `gh` commands** in `examples/.claude/loop.md` that run without a prompt are listed in `permissions.allow` in `settings.json`.
- **The subagent names** `verify-app` and `reviewer`, and their output formats (`RESULT: PASS | FAIL | BLOCKED`, `VERDICT: APPROVE | CHANGES NEEDED`), are used in `examples/CLAUDE.md`, `examples/SPEC.md`, and the `/goal` condition in `examples/README.md`.
- **The loop stages** (spec → `/goal` → `/loop`) and the setup steps are in `README.md`, `examples/README.md`, and `docs/summary.html`.
- **The hook behavior** (skip when git is clean, exit code 2 blocks, `MAX_BLOCKS` default 5, last 40 lines of output) is described in `examples/README.md`.
- **The file tree** in `examples/README.md` must match the real files.

## Claims and sources

- Every new claim about Claude Code features, or quote from Boris Cherny or Anthropic, needs a row in `docs/sources.md`.
- If a claim is not confirmed, put it under "Not fully confirmed" in `sources.md`, or add it to `docs/open-questions.md`.
- Say when a number is an estimate, not a measured result (for example, the "2–3 times better" figure).
- When you resolve an open question, tick its box in `docs/open-questions.md` and fix the guide text.

## Writing style

The guide uses plain English: short sentences, active voice, no idioms, and each technical term explained the first time. Match this in every file, including the example files.
