#!/usr/bin/env bash
# PostToolUse hook: format the file Claude just edited.
# Claude Code sends the tool call as JSON on stdin.
# Change the formatter commands to match your project.

file=$(jq -r '.tool_input.file_path // empty')
[ -z "$file" ] || [ ! -f "$file" ] && exit 0

case "$file" in
  *.js|*.jsx|*.ts|*.tsx|*.json|*.css|*.md) npx --no-install prettier --write "$file" >/dev/null 2>&1 ;;
  *.py) ruff format "$file" >/dev/null 2>&1 ;;
  *.go) gofmt -w "$file" >/dev/null 2>&1 ;;
esac

# Never block Claude because the formatter is missing or failed.
exit 0
