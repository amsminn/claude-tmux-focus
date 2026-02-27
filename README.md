# claude-tmux-focus

Claude Code plugin that automatically focuses your tmux pane when Claude needs your attention.

When Claude Code emits a **Notification** event (e.g., waiting for user input or permission approval), this plugin:

1. Switches to the tmux window containing the Claude session
2. Focuses the correct pane
3. Highlights the pane background until you respond
4. Shows a tmux status message
5. Sends a system notification (macOS / Linux)

## Requirements

- **tmux**
- **jq**

### Optional

| Tool | Platform | Purpose |
|------|----------|---------|
| `terminal-notifier` | macOS | System notifications (`brew install terminal-notifier`) |
| `notify-send` | Linux | System notifications (`apt install libnotify-bin`) |

## Installation

### From GitHub

Claude Code 안에서:

```
/plugin marketplace add chaewan/claude-tmux-focus
/plugin install claude-tmux-focus@chaewan-claude-tmux-focus
```

### From local directory (개발용)

```bash
claude --plugin-dir ./claude-tmux-focus
```

### 관리

```bash
claude plugin list
claude plugin disable claude-tmux-focus
claude plugin enable claude-tmux-focus
claude plugin uninstall claude-tmux-focus
```

## Configuration

Edit `config/user-config.json` inside the plugin directory to customize behavior.
If the file doesn't exist, `config/default-config.json` is used.

```json
{
  "enableNotification": true,
  "enableMacOSNotifier": true,
  "enableLinuxNotifier": true,
  "highlightColor": "blue",
  "tmuxMessageDuration": 3000,
  "logLevel": "info"
}
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enableNotification` | boolean | `true` | Enable/disable system notifications |
| `enableMacOSNotifier` | boolean | `true` | Use terminal-notifier on macOS |
| `enableLinuxNotifier` | boolean | `true` | Use notify-send on Linux |
| `highlightColor` | string | `"blue"` | tmux color for pane highlight |
| `tmuxMessageDuration` | number | `3000` | tmux message display duration in ms |
| `logLevel` | string | `"info"` | `"debug"`, `"info"`, `"warn"`, `"error"` |

## How It Works

```
Notification event               UserPromptSubmit event
        │                                 │
        ▼                                 ▼
  tmux-focus.sh                     tmux-clear.sh
        │                                 │
        ├─ inside tmux? ─no─▶ exit 0      ├─ inside tmux? ─no─▶ exit 0
        │       │                         │       │
        │      yes                        │      yes
        ▼       ▼                         ▼       ▼
  select-window + select-pane       clear_highlight
        │                           (restore original style)
        ├─ highlight pane ON
        ├─ display-message
        └─ system notification
```

## Project Structure

```
claude-tmux-focus/
├── .claude-plugin/
│   ├── plugin.json             # Plugin manifest
│   └── marketplace.json        # Marketplace definition
├── hooks/
│   └── hooks.json              # Notification + UserPromptSubmit hooks
├── scripts/
│   ├── tmux-focus.sh           # Notification → focus + highlight on
│   ├── tmux-clear.sh           # UserPromptSubmit → highlight off
│   ├── tmux-control.sh         # tmux window/pane control
│   ├── notify.sh               # Cross-platform notifications
│   └── config.sh               # Config loader + logging
├── config/
│   └── default-config.json     # Default settings
└── README.md
```

## Logs

```bash
tail -f /path/to/claude-tmux-focus/logs/tmux-focus.log
```

Set `logLevel` to `"debug"` for verbose output.

## Security

- All external commands use direct arguments, no shell interpolation or `eval`
- stdin JSON is read but never executed
- Every command is wrapped in error handling — always exits 0 to not disrupt Claude Code
- Original pane style stored in a per-pane state file, written once and consumed once

## License

MIT
