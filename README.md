# Taxi Meter for Claude Code

A seven-segment token display for your Claude Code status line. Shows live context window usage, cumulative session fare, and effort level in a retro taxi meter style.

```
METER
     _   _
     _| |_  |_|
    |_   _|.  |  K   CTX ██░░░░░░  25%  TARIFF 3 high
FARE      145.0 K
```

## Requirements

- [jq](https://jqlang.github.io/jq/) (`brew install jq` on macOS)

## Install

```bash
git clone https://github.com/zorkzorkzork/zaksclaudetaximeter.git
cd zaksclaudetaximeter
cat install.sh   # read it first
bash install.sh
```

Then restart Claude Code.

## What it shows

- **METER** -- live context window tokens as seven-segment digits (updates every 300ms)
- **CTX bar** -- visual fill of context window (green < 60%, yellow < 80%, red > 80%)
- **Percentage** -- exact context window usage
- **TARIFF** -- current effort level (1 low / 2 medium / 3 high)
- **FARE** -- cumulative session token consumption (only goes up, survives compaction)

Both METER and FARE automatically switch from K (thousands) to M (millions) when they cross 1M tokens.

## How cumulative tracking works

The METER shows what's currently in the context window. When the context fills up and Claude Code compacts (summarizes old messages), the METER drops back down.

The FARE tracks cumulative tokens across the session. It accumulates the growth delta each time the context expands, and adds the full post-compaction context when compaction occurs. State is stored in `/tmp/taxi-meter-{session_id}` and resets when you start a new session.

## Uninstall

Delete the script and remove the `statusLine` block from your settings:

```bash
rm ~/.claude/taxi-meter.sh
```

Then edit `~/.claude/settings.json` and remove the `"statusLine": { ... }` block.
