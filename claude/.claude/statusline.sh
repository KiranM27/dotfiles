#!/bin/bash
input=$(cat)

# Extract fields
MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
FIVE_H_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
SEVEN_D=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
SEVEN_D_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
WORKTREE=$(echo "$input" | jq -r '.worktree.name // empty')
EFFORT=$(echo "$input" | jq -r '.effort.level // empty')
SESSION_ID=$(echo "$input" | jq -r '.session_id // empty')

# --- ctx-monitor tap (see ~/.claude/tools/ctx-monitor/DESIGN.md, Component 1) ---
# Publishes context usage for tmux-resident sessions. No-op when not in tmux.
# Must never break the statusline: every failure is swallowed, nothing is
# written to stdout, and the write is atomic (tmp file + mv).
# Inputs are sanitized at this boundary: SESSION_ID is constrained to UUID
# characters so it cannot escape CTX_DIR via path traversal; PCT is forced to
# an integer; the ts command substitution has a 0 fallback. All three keep a
# malformed payload from silently breaking the tap or escaping the tmp dir.
if [ -n "$TMUX_PANE" ] && [ -n "$SESSION_ID" ]; then
    # SESSION_ID flows into a filename — reject anything that isn't UUID-shaped
    # (hex + dashes). A non-conforming value is blanked, and the [ -n ] gate
    # below skips publishing rather than writing outside CTX_DIR.
    case "$SESSION_ID" in (*[!0-9A-Fa-f-]*) SESSION_ID="" ;; esac
    # PCT feeds --argjson (must be valid JSON); force it to an integer.
    case "$PCT" in (''|*[!0-9]*) PCT=0 ;; esac
    if [ -n "$SESSION_ID" ]; then
        CTX_DIR="/tmp/claude-ctx"
        mkdir -p "$CTX_DIR" 2>/dev/null
        CTX_TMP=$(mktemp "$CTX_DIR/.tap.XXXXXX" 2>/dev/null) && \
        jq -n \
            --arg session_id "$SESSION_ID" \
            --argjson pct "${PCT:-0}" \
            --arg pane "$TMUX_PANE" \
            --arg cwd "$DIR" \
            --argjson ts "$(date +%s 2>/dev/null || echo 0)" \
            --arg model "${MODEL:-}" \
            --arg effort "${EFFORT:-}" \
            --arg worktree "${WORKTREE:-}" \
            --arg five_h_pct "${FIVE_H:-}" \
            --arg five_h_reset "${FIVE_H_RESET:-}" \
            --arg seven_d_pct "${SEVEN_D:-}" \
            --arg seven_d_reset "${SEVEN_D_RESET:-}" \
            '{session_id: $session_id, pct: $pct, pane: $pane, cwd: $cwd, ts: $ts, model: $model, effort: $effort, worktree: $worktree, five_h_pct: $five_h_pct, five_h_reset: $five_h_reset, seven_d_pct: $seven_d_pct, seven_d_reset: $seven_d_reset}' \
            > "$CTX_TMP" 2>/dev/null && \
        mv "$CTX_TMP" "$CTX_DIR/$SESSION_ID.json" 2>/dev/null || rm -f "$CTX_TMP" 2>/dev/null
    fi
fi
# --- end ctx-monitor tap ---

# --- per-session working-dir override (worktree mode) ---
# A session can point the statusline at the dir it's actually working in
# (e.g. a git worktree it edits via absolute paths, when the session itself
# was launched in the main checkout). Write that path to
#   /tmp/claude-statusline-override/<session_id>
# and the folder + branch below reflect it instead of the launch dir.
# Keyed by session id so it ONLY affects this window — never other CC
# windows on the same shared repo. Remove the file to revert.
if [ -n "$SESSION_ID" ]; then
    OVR_FILE="/tmp/claude-statusline-override/$SESSION_ID"
    if [ -f "$OVR_FILE" ]; then
        OVR_DIR=$(cat "$OVR_FILE" 2>/dev/null)
        [ -n "$OVR_DIR" ] && [ -d "$OVR_DIR" ] && DIR="$OVR_DIR"
    fi
fi
# --- end override ---

# Colors
DIM='\033[90m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
MAGENTA='\033[35m'
WHITE='\033[97m'
RESET='\033[0m'

# Folder name
FOLDER="${DIR##*/}"

# Git branch (cached for performance).
# Cache keyed per session so concurrent CC windows on different branches/
# worktrees never clobber each other's cached branch (and so the override
# dir above is reflected). Branch is read from $DIR, which honors the override.
CACHE_FILE="/tmp/statusline-git-cache-${SESSION_ID:-shared}"
CACHE_MAX_AGE=5
cache_is_stale() {
    [ ! -f "$CACHE_FILE" ] || \
    [ $(($(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0))) -gt $CACHE_MAX_AGE ]
}
if cache_is_stale; then
    BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null || echo "")
    echo "$BRANCH" > "$CACHE_FILE"
else
    BRANCH=$(cat "$CACHE_FILE")
fi

# Context bar color
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

# Build progress bar
BAR_WIDTH=10
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && printf -v FILL "%${FILLED}s" && BAR="${FILL// /█}"
[ "$EMPTY" -gt 0 ] && printf -v PAD "%${EMPTY}s" && BAR="${BAR}${PAD// /░}"

# Format cost
COST_FMT=$(printf '$%.2f' "$COST")

# Build output
LINE=""
LINE="${WHITE}${FOLDER}${RESET}"

[ -n "$BRANCH" ] && LINE="${LINE} ${DIM}/${RESET} ${CYAN}${BRANCH}${RESET}"

[ -n "$WORKTREE" ] && LINE="${LINE} ${DIM}/${RESET} ${MAGENTA}wt:${WORKTREE}${RESET}"

LINE="${LINE} ${DIM}|${RESET} ${WHITE}${MODEL}${RESET}"

if [ -n "$EFFORT" ]; then
    case "$EFFORT" in
        low)    EFF_COLOR="$DIM" ;;
        medium) EFF_COLOR="$CYAN" ;;
        high)   EFF_COLOR="$GREEN" ;;
        xhigh)  EFF_COLOR="$YELLOW" ;;
        max)    EFF_COLOR="$RED" ;;
        *)      EFF_COLOR="$WHITE" ;;
    esac
    LINE="${LINE} ${DIM}|${RESET} ${EFF_COLOR}${EFFORT}${RESET}"
fi

LINE="${LINE} ${DIM}|${RESET} ${BAR_COLOR}${BAR} ${PCT}%${RESET}"

LINE="${LINE} ${DIM}|${RESET} ${YELLOW}${COST_FMT}${RESET}"

if [ -n "$FIVE_H" ]; then
    FIVE_H_INT=$(printf '%.0f' "$FIVE_H")
    if [ "$FIVE_H_INT" -ge 80 ]; then RL_COLOR="$RED"
    elif [ "$FIVE_H_INT" -ge 50 ]; then RL_COLOR="$YELLOW"
    else RL_COLOR="$GREEN"; fi
    RL_TEXT="5h:${FIVE_H_INT}%"
    if [ -n "$FIVE_H_RESET" ]; then
        NOW=$(date +%s)
        REMAINING=$((FIVE_H_RESET - NOW))
        if [ "$REMAINING" -gt 0 ]; then
            HOURS=$((REMAINING / 3600))
            MINS=$(((REMAINING % 3600) / 60))
            if [ "$HOURS" -gt 0 ]; then
                RL_TEXT="${RL_TEXT} (${HOURS}h${MINS}m)"
            else
                RL_TEXT="${RL_TEXT} (${MINS}m)"
            fi
        fi
    fi
    LINE="${LINE} ${DIM}|${RESET} ${RL_COLOR}${RL_TEXT}${RESET}"
fi

printf '%b\n' "$LINE"
