#!/usr/bin/env bash
# tmux-focus.sh — Main entry point for claude-tmux-focus plugin
# Called by Claude Code on Notification/Stop events.
# Focuses the tmux pane, shows visual feedback, and sends system notifications.
# Includes debounce to avoid flicker when multiple agents finish near-simultaneously.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/tmux-control.sh"
source "$SCRIPT_DIR/notify.sh"

DEBOUNCE_SECONDS=2
LOCK_FILE="$LOG_DIR/focus.lock"

# Debounce: skip if another focus ran within DEBOUNCE_SECONDS
should_skip() {
    if [[ -f "$LOCK_FILE" ]]; then
        local last
        last=$(cat "$LOCK_FILE" 2>/dev/null || echo 0)
        local now
        now=$(date +%s)
        local diff=$(( now - last ))
        if [[ $diff -lt $DEBOUNCE_SECONDS ]]; then
            log_debug "Debounced (${diff}s since last focus)"
            return 0
        fi
    fi
    return 1
}

touch_lock() {
    date +%s > "$LOCK_FILE" 2>/dev/null || true
}

main() {
    log_info "Event received"

    # Read event data from stdin (Claude Code passes JSON)
    local input=""
    if ! [ -t 0 ]; then
        input=$(cat 2>/dev/null || true)
    fi
    log_debug "Event payload: $input"

    # 1. Check if running inside tmux
    if ! is_inside_tmux; then
        log_info "Not inside tmux — exiting gracefully"
        exit 0
    fi

    # 2. Debounce — skip if recently focused
    if should_skip; then
        exit 0
    fi
    touch_lock

    log_debug "Running in tmux session (TMUX_PANE=${TMUX_PANE})"

    # 3. Focus the pane
    if ! focus_pane; then
        log_error "Failed to focus pane — aborting"
        exit 0
    fi

    # 4. Show tmux display-message
    show_tmux_message "Claude: Input required (focused)" || true

    # 5. Highlight pane
    highlight_pane || true

    # 6. Send system notification
    send_notification "Claude Code" "Input required - switched to pane" || true

    log_info "Focus sequence completed for pane ${TMUX_PANE}"
    exit 0
}

trap 'log_warn "Received signal, exiting"; exit 0' INT TERM HUP
main "$@"
