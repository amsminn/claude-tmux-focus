#!/usr/bin/env bash
# tmux-focus.sh — Main entry point for claude-tmux-focus plugin
# Called by Claude Code on Notification/Stop events.
# Idempotent: if pane is already highlighted, only re-focuses without re-notifying.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/tmux-control.sh"
source "$SCRIPT_DIR/notify.sh"

main() {
    # Drain stdin
    if ! [ -t 0 ]; then
        cat >/dev/null 2>&1 || true
    fi

    if ! is_inside_tmux; then
        exit 0
    fi

    # Always focus the pane (cheap, idempotent)
    focus_pane || exit 0

    # If already highlighted, skip notification — just ensure focus
    if is_highlighted; then
        log_debug "Already highlighted, focus only"
        exit 0
    fi

    # First time: highlight + message + notify
    highlight_pane || true
    show_tmux_message "Claude: Input required (focused)" || true
    send_notification "Claude Code" "Input required - switched to pane" || true

    log_info "Focused and notified pane ${TMUX_PANE}"
    exit 0
}

trap 'exit 0' INT TERM HUP
main "$@"
