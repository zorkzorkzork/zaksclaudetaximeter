# Taxi Meter for Claude Code

A seven-segment token display for your Claude Code status line. Shows live context window usage, cumulative session fare, and effort level in a retro taxi meter style.

```
FARE
     _   _
     _| |_  |_|
    |_   _|.  |  K   CTX ██░░░░░░  25%  TARIFF 3 high  opus 4.6  RATE ░░░░░░░░ 1% resets 19:20
TRIP      145.0 K
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

- **FARE** -- live context window tokens as seven-segment digits
- **CTX bar** -- visual fill of context window (green < 60%, yellow < 80%, red > 80%)
- **TARIFF** -- current effort level (1 low / 2 medium / 3 high / 4 xhigh / 5 max)
- **Model** -- active model name (opus 4.6, sonnet 4.6, haiku 4.5, etc.)
- **RATE** -- 5-hour rate limit usage bar with reset time in your local timezone
- **TRIP** -- cumulative session token consumption (only goes up, survives compaction)

FARE and TRIP automatically switch from K (thousands) to M (millions) when they cross 1M tokens.

## How cumulative tracking works

The FARE shows what's currently in the context window. When the context fills up and Claude Code compacts (summarizes old messages), the FARE drops back down.

The TRIP tracks cumulative tokens across the session. It accumulates the growth delta each time the context expands, and adds the full post-compaction context when compaction occurs. State is stored in `/tmp/taxi-meter-{session_id}` and resets when you start a new session.

## Uninstall

Delete the script and remove the `statusLine` block from your settings:

```bash
rm ~/.claude/taxi-meter.sh
```

Then edit `~/.claude/settings.json` and remove the `"statusLine": { ... }` block.
