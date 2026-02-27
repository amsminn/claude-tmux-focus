#!/usr/bin/env bash
# tmux-clear.sh — Called on UserPromptSubmit to clear the pane highlight.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/tmux-control.sh"

main() {
    if ! is_inside_tmux; then
        exit 0
    fi

    # Drain stdin
    if ! [ -t 0 ]; then
        cat >/dev/null 2>&1 || true
    fi

    clear_highlight
    log_debug "Highlight cleared on user input"
    exit 0
}

trap 'exit 0' INT TERM HUP
main "$@"
