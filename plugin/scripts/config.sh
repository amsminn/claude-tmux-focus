#!/usr/bin/env bash
# config.sh — Configuration loader for claude-tmux-focus
# Reads settings from user config or falls back to defaults.

# Include guard to prevent double-sourcing
if [[ -n "${_CONFIG_SH_LOADED:-}" ]]; then
    return 0 2>/dev/null || true
fi
_CONFIG_SH_LOADED=1

set -euo pipefail

# Resolve plugin root relative to this script
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

DEFAULT_CONFIG="$PLUGIN_ROOT/config/default-config.json"
USER_CONFIG="$PLUGIN_ROOT/config/user-config.json"
LOG_DIR="$PLUGIN_ROOT/logs"
LOG_FILE="$LOG_DIR/tmux-focus.log"

# Initialize log directory
mkdir -p "$LOG_DIR"

# Read a config value. User config overrides default config.
# Usage: config_get <key> [fallback]
config_get() {
    local key="$1"
    local fallback="${2:-}"
    local value=""

    # Try user config first
    if [[ -f "$USER_CONFIG" ]]; then
        value=$(jq -r --arg k "$key" '.[$k] // empty' "$USER_CONFIG" 2>/dev/null || true)
    fi

    # Fall back to default config
    if [[ -z "$value" ]] && [[ -f "$DEFAULT_CONFIG" ]]; then
        value=$(jq -r --arg k "$key" '.[$k] // empty' "$DEFAULT_CONFIG" 2>/dev/null || true)
    fi

    # Fall back to provided default
    if [[ -z "$value" ]]; then
        value="$fallback"
    fi

    printf '%s' "$value"
}

# Logging functions
log() {
    local level="$1"
    shift
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    printf '[%s] [%s] %s\n' "$timestamp" "$level" "$*" >> "$LOG_FILE" 2>/dev/null || true
}

log_info()  { log "INFO"  "$@"; }
log_warn()  { log "WARN"  "$@"; }
log_error() { log "ERROR" "$@"; }
log_debug() {
    local log_level
    log_level=$(config_get "logLevel" "info")
    if [[ "$log_level" == "debug" ]]; then
        log "DEBUG" "$@"
    fi
}
