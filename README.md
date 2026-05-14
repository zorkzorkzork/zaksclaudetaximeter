# Taxi Meter for Claude Code

A seven-segment token display for your Claude Code status line. Shows session token usage, context window percentage, and effort level in a retro taxi meter style.

```
FARE
     _   _
     _| |_  |_|
    |_   _|.  |  K   ░░░░░░░░  12%  TARIFF 3 high
```

## Requirements

- [jq](https://jqlang.github.io/jq/) (`brew install jq` on macOS)

## Install

```bash
git clone https://github.com/genmomentum/taxi-meter.git
cd taxi-meter
cat install.sh   # read it first
bash install.sh
```

Then restart Claude Code.

## What it shows

- **FARE** -- session token usage in thousands (K), rendered as seven-segment digits
- **Context bar** -- visual fill of context window (green/yellow/red)
- **Percentage** -- exact context window usage
- **Tariff** -- current effort level (low/medium/high)

## Uninstall

Delete the script and remove the `statusLine` block from your settings:

```bash
rm ~/.claude/taxi-meter.sh
```

Then edit `~/.claude/settings.json` and remove the `"statusLine": { ... }` block.
