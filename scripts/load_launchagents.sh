#!/bin/bash

# LaunchAgent Loader
# Registers the stowed LaunchAgents with launchd. Stowing only places the plist
# symlink in ~/Library/LaunchAgents — it does NOT tell launchd the job exists.
# Without this step the agent never starts, at login or otherwise.
#
# Idempotent: boots out any existing registration before bootstrapping, so it is
# safe to re-run (and picks up plist edits, which launchd otherwise caches).

set -e

LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
DOMAIN="gui/$(id -u)"

# Labels to register, and the path each one's ProgramArguments depends on.
# A dependency that does not resolve means the job would crash-loop, so we skip
# it with a warning instead of registering something broken.
AGENTS=(
    "sg.lexi.ctx-monitor:$HOME/.claude/tools/ctx-monitor/ctx-monitor.py"
)

echo "🚀 LaunchAgent Registration"
echo "Domain: $DOMAIN"
echo ""

load_agent() {
    local label="$1"
    local dependency="$2"
    local plist="$LAUNCH_AGENTS_DIR/$label.plist"

    if [ ! -e "$plist" ]; then
        echo "  ⚠️  $label: plist not found at $plist (run stow first), skipping"
        return 0
    fi

    if [ -n "$dependency" ] && [ ! -e "$dependency" ]; then
        echo "  ⚠️  $label: needs $dependency, which does not resolve yet."
        echo "      Clone agents-cockpit and create its symlinks, then re-run:"
        echo "      ./scripts/load_launchagents.sh"
        return 0
    fi

    if ! plutil -lint "$plist" > /dev/null 2>&1; then
        echo "  ❌ $label: plist is malformed, skipping"
        return 0
    fi

    # bootout first so a re-run reloads an edited plist rather than no-oping.
    launchctl bootout "$DOMAIN/$label" 2> /dev/null || true
    launchctl bootstrap "$DOMAIN" "$plist"
    launchctl enable "$DOMAIN/$label"
    echo "  ✅ $label: registered"
}

for entry in "${AGENTS[@]}"; do
    load_agent "${entry%%:*}" "${entry#*:}"
done

echo ""
echo "📊 Status (PID / last exit code / label):"
launchctl list | grep -E "$(printf '%s|' "${AGENTS[@]%%:*}" | sed 's/|$//')" || \
    echo "  (nothing registered)"

echo ""
echo "🎉 LaunchAgent registration complete!"
