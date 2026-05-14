#!/usr/bin/env bash
set -euo pipefail

DEST="$HOME/.claude/taxi-meter.sh"
SETTINGS="$HOME/.claude/settings.json"

mkdir -p "$HOME/.claude"

cat > "$DEST" << 'METER'
#!/usr/bin/env bash
INPUT=$(cat)

eval "$(echo "$INPUT" | jq -r '
  @sh "TOKENS=\(.context_window.total_input_tokens // 0)
  PCT=\(.context_window.used_percentage // 0)
  EFFORT=\(.effort.level // "medium")
  SID=\(.session_id // "default")"
' 2>/dev/null)" || exit 0

PCT_INT=${PCT%.*}
: "${PCT_INT:=0}"

STATE="/tmp/taxi-meter-${SID}"
if [ -f "$STATE" ]; then
  read PREV_IN CUMULATIVE < "$STATE"
else
  PREV_IN=0; CUMULATIVE=0
fi
if [ "$TOKENS" -gt "$PREV_IN" ] 2>/dev/null; then
  CUMULATIVE=$((CUMULATIVE + TOKENS - PREV_IN))
  echo "$TOKENS $CUMULATIVE" > "$STATE"
elif [ "$TOKENS" -lt "$PREV_IN" ] 2>/dev/null && [ "$TOKENS" -gt 0 ] 2>/dev/null; then
  CUMULATIVE=$((CUMULATIVE + TOKENS))
  echo "$TOKENS $CUMULATIVE" > "$STATE"
elif [ ! -f "$STATE" ]; then
  echo "$TOKENS $CUMULATIVE" > "$STATE"
fi

if [ "$TOKENS" -ge 1000000 ] 2>/dev/null; then
  M_W=$((TOKENS / 1000000))
  M_F=$(( (TOKENS % 1000000) / 100000 ))
  FARE_STR=$(printf "%3d.%d" "$M_W" "$M_F")
  UNIT="M"
elif [ "$TOKENS" -gt 0 ] 2>/dev/null; then
  K_W=$((TOKENS / 1000))
  K_F=$(( (TOKENS % 1000) / 100 ))
  FARE_STR=$(printf "%3d.%d" "$K_W" "$K_F")
  UNIT="K"
else
  FARE_STR="  0.0"
  UNIT="K"
fi

if [ "$CUMULATIVE" -ge 1000000 ] 2>/dev/null; then
  TM_W=$((CUMULATIVE / 1000000))
  TM_F=$(( (CUMULATIVE % 1000000) / 100000 ))
  TRIP_NUM=$(printf "%d.%d" "$TM_W" "$TM_F")
  TRIP_UNIT="M"
elif [ "$CUMULATIVE" -gt 0 ] 2>/dev/null; then
  TK_W=$((CUMULATIVE / 1000))
  TK_F=$(( (CUMULATIVE % 1000) / 100 ))
  TRIP_NUM=$(printf "%d.%d" "$TK_W" "$TK_F")
  TRIP_UNIT="K"
else
  TRIP_NUM="0.0"
  TRIP_UNIT="K"
fi

L0="" L1="" L2=""
prev=""
for (( i=0; i<${#FARE_STR}; i++ )); do
  c="${FARE_STR:$i:1}"
  if [ "$c" = "." ]; then
    L0+=" "; L1+=" "; L2+="."
    prev="."
    continue
  fi
  if [ $i -gt 0 ] && [ "$prev" != "." ]; then
    L0+=" "; L1+=" "; L2+=" "
  fi
  case "$c" in
    0) L0+=" _ "; L1+="| |"; L2+="|_|" ;;
    1) L0+="   "; L1+="  |"; L2+="  |" ;;
    2) L0+=" _ "; L1+=" _|"; L2+="|_ " ;;
    3) L0+=" _ "; L1+=" _|"; L2+=" _|" ;;
    4) L0+="   "; L1+="|_|"; L2+="  |" ;;
    5) L0+=" _ "; L1+="|_ "; L2+=" _|" ;;
    6) L0+=" _ "; L1+="|_ "; L2+="|_|" ;;
    7) L0+=" _ "; L1+="  |"; L2+="  |" ;;
    8) L0+=" _ "; L1+="|_|"; L2+="|_|" ;;
    9) L0+=" _ "; L1+="|_|"; L2+=" _|" ;;
    ' ') L0+="   "; L1+="   "; L2+="   " ;;
  esac
  prev="$c"
done

BAR_W=8
FILLED=$((PCT_INT * BAR_W / 100))
[ "$FILLED" -gt "$BAR_W" ] && FILLED=$BAR_W
EMPTY=$((BAR_W - FILLED))
if [ "$PCT_INT" -gt 80 ]; then BC="\033[91m"
elif [ "$PCT_INT" -gt 60 ]; then BC="\033[93m"
else BC="\033[92m"; fi
BAR=""
j=0; while [ "$j" -lt "$FILLED" ]; do BAR+="█"; j=$((j+1)); done
j=0; while [ "$j" -lt "$EMPTY" ]; do BAR+="░"; j=$((j+1)); done

case "$EFFORT" in
  low)    TF="TARIFF 1 low" ;;
  high)   TF="TARIFF 3 high" ;;
  *)      TF="TARIFF 2 medium" ;;
esac

R="\033[1;91m"; D="\033[31m"; G="\033[90m"; X="\033[0m"

printf "${D}FARE${X}\n"
printf "${R}%s${X}\n" "$L0"
printf "${R}%s${X}\n" "$L1"
printf "${R}%s${X} ${G}%s${X}   ${D}CTX${X} ${BC}%s${X} ${G}%s%%${X}  ${D}%s${X}\n" "$L2" "$UNIT" "$BAR" "$PCT_INT" "$TF"
printf "${D}TRIP${X}  ${G}%9s %s${X}\n" "$TRIP_NUM" "$TRIP_UNIT"
METER

chmod +x "$DEST"

if [ -f "$SETTINGS" ]; then
  if jq -e '.statusLine' "$SETTINGS" > /dev/null 2>&1; then
    echo "taxi-meter.sh installed to $DEST"
    echo ""
    echo "Your settings.json already has a statusLine entry."
    echo "Make sure it points to: ~/.claude/taxi-meter.sh"
  else
    jq '. + {"statusLine":{"type":"command","command":"~/.claude/taxi-meter.sh","updateIntervalMs":300}}' "$SETTINGS" > "$SETTINGS.tmp" \
      && mv "$SETTINGS.tmp" "$SETTINGS"
    echo "taxi-meter.sh installed and settings.json updated."
  fi
else
  cat > "$SETTINGS" << 'EOF'
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/taxi-meter.sh",
    "updateIntervalMs": 300
  }
}
EOF
  echo "taxi-meter.sh installed and settings.json created."
fi

echo ""
echo "Restart Claude Code to see the taxi meter."
