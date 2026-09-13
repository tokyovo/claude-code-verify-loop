#!/usr/bin/env bash
# Drive an interactive Claude Code session in tmux, for field tests of the guide.
# /goal and /loop need a live session, so `claude -p` cannot test them.
#
# Usage:
#   drive.sh start  <session> <dir> [claude args...]   start claude in <dir> and accept the trust dialog
#   drive.sh send   <session> <text>                   type <text> and press Enter, do not wait
#   drive.sh ask    <session> <text> [seconds]         send <text>, then wait for the turn to end or a prompt
#   drive.sh keys   <session> <key...>                 press keys in a dialog (for example: Down Enter), then wait
#   drive.sh wait   <session> <regex> [seconds]        wait until the screen matches <regex> (default 600 s)
#   drive.sh screen <session> [lines]                  print the last lines of the screen (default 40)
#   drive.sh stop   <session>                          end the session
#
# ask and keys exit 0 when the turn ends, 3 when a dialog or permission prompt waits for input, 1 on timeout.
# While waiting, the script answers "Not now" to the "Teach auto mode" prompt and prints a note when it does.

cmd="$1"
s="$2"
shift 2

screen() { tmux capture-pane -p -t "$s" -S -"${1:-200}" | grep -v '^\s*$'; }

# A working turn shows a spinner line such as "✻ Fermenting… (30s · ↓ 2.1k tokens)"
# or "✢ Quantumizing… (running stop hook · 48s · ↓ 3.3k tokens)".
busy() { screen 400 | tail -15 | grep -Eq '…[[:space:]]*\(.*[0-9]+s( ·|\))'; }
# Dialogs and permission prompts end with a key hint line. Plain text such as "Do you want me to..." is not a prompt.
prompt_open() { printf '%s\n' "$1" | grep -Eq "Enter to confirm|Enter to select|Esc to cancel"; }

# Wait until the turn ends or a new dialog opens. $1 = the screen tail before the action.
wait_turn() {
  local before_tail="$1" limit="${2:-900}" start saw_busy=0 idle=0 tail_now
  start=$(date +%s)
  while [ $(($(date +%s) - start)) -lt "$limit" ]; do
    sleep 3
    if screen 60 | grep -q "Teach auto mode about your environment"; then
      tmux send-keys -t "$s" Down Enter
      echo "note: answered 'Not now' to the Teach auto mode prompt"
      continue
    fi
    tail_now=$(screen 400 | tail -14)
    if [ "$tail_now" != "$before_tail" ] && prompt_open "$tail_now"; then
      echo "input needed after $(($(date +%s) - start)) s"
      screen 400 | tail -40
      return 3
    fi
    if busy; then
      saw_busy=1
      idle=0
    elif [ "$saw_busy" = 1 ] || [ $(($(date +%s) - start)) -ge 60 ]; then
      idle=$((idle + 1))
      if [ "$idle" -ge 2 ]; then
        echo "turn ended after $(($(date +%s) - start)) s"
        screen 400 | tail -60
        return 0
      fi
    fi
  done
  echo "timeout after $limit s" >&2
  screen 400 | tail -40
  return 1
}

case "$cmd" in
  start)
    dir="$1"
    shift
    tmux new-session -d -s "$s" -x 200 -y 50 -c "$dir" "claude $*" || exit 1
    tmux set-option -t "$s" history-limit 100000 >/dev/null
    for _ in $(seq 1 30); do
      if screen | grep -q "trust this folder"; then
        tmux send-keys -t "$s" Down Enter
        echo "accepted trust dialog"
      fi
      if screen | grep -q "for shortcuts\|auto mode on\|plan mode on\|^❯"; then
        # The prompt line appears before the input accepts keys. Without this pause the first Enter can be lost.
        sleep 4
        echo "session ready"
        exit 0
      fi
      sleep 1
    done
    echo "session did not become ready" >&2
    exit 1
    ;;
  send)
    tmux send-keys -t "$s" -l "$1"
    tmux send-keys -t "$s" Enter
    ;;
  ask)
    before_tail=$(screen 400 | tail -14)
    tmux send-keys -t "$s" -l "$1"
    tmux send-keys -t "$s" Enter
    wait_turn "$before_tail" "${2:-900}"
    exit $?
    ;;
  keys)
    before_tail=$(screen 400 | tail -14)
    tmux send-keys -t "$s" "$@"
    wait_turn "$before_tail" 900
    exit $?
    ;;
  wait)
    regex="$1"
    limit="${2:-600}"
    start=$(date +%s)
    while [ $(($(date +%s) - start)) -lt "$limit" ]; do
      if screen 60 | grep -q "Teach auto mode about your environment"; then
        tmux send-keys -t "$s" Down Enter
        echo "note: answered 'Not now' to the Teach auto mode prompt"
      fi
      if screen 400 | grep -Eq "$regex"; then
        echo "matched after $(($(date +%s) - start)) s"
        exit 0
      fi
      sleep 3
    done
    echo "timeout after $limit s" >&2
    exit 1
    ;;
  screen)
    screen 400 | tail -"${1:-40}"
    ;;
  stop)
    tmux kill-session -t "$s"
    ;;
  *)
    echo "unknown command: $cmd" >&2
    exit 2
    ;;
esac
