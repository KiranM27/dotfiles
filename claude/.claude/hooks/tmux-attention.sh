#!/bin/bash
# Tint this session's tmux pane when Claude Code needs attention; clear when work resumes.
# Usage: tmux-attention.sh on|off   (silent no-op outside tmux)
[ -n "$TMUX_PANE" ] || exit 0
TMUX_BIN=$(command -v tmux || echo /opt/homebrew/bin/tmux)
[ -x "$TMUX_BIN" ] || exit 0
case "$1" in
  on)  "$TMUX_BIN" select-pane -t "$TMUX_PANE" -P 'bg=colour52' 2>/dev/null ;;
  off) "$TMUX_BIN" select-pane -t "$TMUX_PANE" -P 'default' 2>/dev/null ;;
esac
exit 0
