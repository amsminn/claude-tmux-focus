#!/usr/bin/env bash
# tmux-control.sh — tmux pane focus and highlight control
# Provides functions for selecting windows/panes and visual feedback.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Check if running inside tmux.
# Returns 0 if inside tmux, 1 otherwise.
is_inside_tmux() {
    if [[ -z "${TMUX:-}" ]] || [[ -z "${TMUX_PANE:-}" ]]; then
        return 1
    fi
    return 0
}

# Get the window ID that contains the current pane.
# Outputs the window ID or returns 1 on failure.
get_pane_window() {
    local pane="${TMUX_PANE}"
    tmux display-message -t "$pane" -p '#{window_id}' 2>/dev/null
}

# Select (focus) the window containing the target pane.
select_window() {
    local pane="${TMUX_PANE}"
    local window_id
    window_id=$(get_pane_window) || {
        log_error "Failed to resolve window for pane $pane"
        return 1
    }
    tmux select-window -t "$window_id" 2>/dev/null || {
        log_error "Failed to select window $window_id"
        return 1
    }
    log_debug "Selected window $window_id"
}

# Select (focus) the target pane.
select_pane() {
    local pane="${TMUX_PANE}"
    tmux select-pane -t "$pane" 2>/dev/null || {
        log_error "Failed to select pane $pane"
        return 1
    }
    log_debug "Selected pane $pane"
}

# Focus the window and pane. Returns 0 on success.
focus_pane() {
    select_window || return 1
    select_pane  || return 1
    log_info "Focused pane ${TMUX_PANE}"
    return 0
}

# Show a tmux display-message on the target pane's session.
show_tmux_message() {
    local message="$1"
    local duration_ms
    duration_ms=$(config_get "tmuxMessageDuration" "3000")

    # tmux display-time is in milliseconds
    tmux display-message -d "$duration_ms" "$message" 2>/dev/null || {
        log_warn "Failed to display tmux message"
        return 1
    }
    log_debug "Displayed tmux message: $message"
}

# State file for storing original pane style before highlight.
_state_file() {
    printf '%s/highlight-state-%s' "$LOG_DIR" "${TMUX_PANE//[^a-zA-Z0-9_]/_}"
}

# Apply highlight to the pane. Persists until clear_highlight is called.
highlight_pane() {
    local pane="${TMUX_PANE}"
    local color
    color=$(config_get "highlightColor" "blue")

    # Save original style only if not already highlighted (don't overwrite)
    local state_file
    state_file=$(_state_file)
    if [[ ! -f "$state_file" ]]; then
        tmux show-options -p -t "$pane" -v window-style 2>/dev/null > "$state_file" || echo "default" > "$state_file"
    fi

    tmux select-pane -t "$pane" -P "bg=$color" 2>/dev/null || {
        log_warn "Failed to apply highlight to pane $pane"
        return 1
    }
    log_debug "Applied highlight color=$color to pane $pane"
}

# Remove highlight and restore original pane style.
clear_highlight() {
    local pane="${TMUX_PANE:-}"
    if [[ -z "$pane" ]]; then
        return 0
    fi

    local state_file
    state_file=$(_state_file)
    if [[ ! -f "$state_file" ]]; then
        return 0
    fi

    local original_style
    original_style=$(cat "$state_file" 2>/dev/null || echo "default")
    rm -f "$state_file"

    if [[ -z "$original_style" || "$original_style" == "default" ]]; then
        tmux select-pane -t "$pane" -P "default" 2>/dev/null || true
    else
        tmux select-pane -t "$pane" -P "$original_style" 2>/dev/null || true
    fi
    log_debug "Cleared highlight on pane $pane"
}
