#!/usr/bin/env bash
# tmux-focus.sh — Main entry point for claude-tmux-focus plugin
# Called by Claude Code on Notification events.
# Focuses the tmux pane, shows visual feedback, and sends system notifications.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/tmux-control.sh"
source "$SCRIPT_DIR/notify.sh"

main() {
    log_info "Notification event received"

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

    log_debug "Running in tmux session (TMUX_PANE=${TMUX_PANE})"

    # 2. Focus the pane
    if ! focus_pane; then
        log_error "Failed to focus pane — aborting"
        exit 0  # Exit 0 to not disrupt Claude Code
    fi

    # 3. Show tmux display-message
    show_tmux_message "Claude: Input required (focused)" || true

    # 4. Highlight pane (non-blocking — runs in background)
    highlight_pane || true

    # 5. Send system notification
    send_notification "Claude Code" "Input required - switched to pane" || true

    log_info "Focus sequence completed for pane ${TMUX_PANE}"
    exit 0
}

# Trap to ensure clean exit on unexpected signals
trap 'log_warn "Received signal, exiting"; exit 0' INT TERM HUP

main "$@"
