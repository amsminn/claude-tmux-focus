#!/usr/bin/env bash
# notify.sh — Cross-platform system notification support
# Supports macOS (terminal-notifier) and Linux (notify-send).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Check if macOS terminal-notifier is available.
has_terminal_notifier() {
    command -v terminal-notifier &>/dev/null
}

# Check if Linux notify-send is available.
has_notify_send() {
    command -v notify-send &>/dev/null
}

# Send a system notification.
# Usage: send_notification <title> <message>
send_notification() {
    local title="$1"
    local message="$2"

    local enable_notification
    enable_notification=$(config_get "enableNotification" "true")
    if [[ "$enable_notification" != "true" ]]; then
        log_debug "System notifications disabled by config"
        return 0
    fi

    case "$(uname -s)" in
        Darwin)
            send_macos_notification "$title" "$message"
            ;;
        Linux)
            send_linux_notification "$title" "$message"
            ;;
        *)
            log_debug "Unsupported OS for system notifications: $(uname -s)"
            ;;
    esac
}

# Send notification on macOS via terminal-notifier.
send_macos_notification() {
    local title="$1"
    local message="$2"

    local enable_macos
    enable_macos=$(config_get "enableMacOSNotifier" "true")
    if [[ "$enable_macos" != "true" ]]; then
        log_debug "macOS notifier disabled by config"
        return 0
    fi

    if ! has_terminal_notifier; then
        log_debug "terminal-notifier not installed, skipping macOS notification"
        return 0
    fi

    # Use array to safely pass arguments — no shell expansion risk
    terminal-notifier -title "$title" -message "$message" -sound default &>/dev/null &
    disown
    log_info "Sent macOS notification: $title - $message"
}

# Send notification on Linux via notify-send.
send_linux_notification() {
    local title="$1"
    local message="$2"

    local enable_linux
    enable_linux=$(config_get "enableLinuxNotifier" "true")
    if [[ "$enable_linux" != "true" ]]; then
        log_debug "Linux notifier disabled by config"
        return 0
    fi

    if ! has_notify_send; then
        log_debug "notify-send not installed, skipping Linux notification"
        return 0
    fi

    notify-send "$title" "$message" &>/dev/null &
    disown
    log_info "Sent Linux notification: $title - $message"
}
