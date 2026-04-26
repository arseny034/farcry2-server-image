#!/usr/bin/env bash
set -euo pipefail

display_num="${DISPLAY#:}"
display_num="${display_num%%.*}"

# Remove stale Xvfb lock/socket left over from a previous run (or aborted build step)
rm -f "/tmp/.X${display_num}-lock" "/tmp/.X11-unix/X${display_num}"

Xvfb "$DISPLAY" -screen 0 1024x768x16 -nolisten tcp &
XVFB_PID=$!

LOG_FILE="${FC2_LOG_FILE:-/data/farcry2/bin/dedicated_log.txt}"
# Make sure the log file exists so tail -F can attach immediately
touch "$LOG_FILE"

# Stream the dedicated server log (the contents of FC2's console window on Windows)
# to container stdout. Start from end so restarts don't replay old output.
tail -n 0 -F "$LOG_FILE" &
TAIL_PID=$!

cleanup() {
    wineserver -k 2>/dev/null || true
    kill "$TAIL_PID" "$XVFB_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Wait for Xvfb to be ready (lock file appears once the server is listening)
for _ in {1..50}; do
    [ -e "/tmp/.X${display_num}-lock" ] && break
    sleep 0.1
done

# Run wine in foreground; its own stdout/stderr also go to the container.
# Drop exec so the trap fires and tail/Xvfb/wineserver get cleaned up.
wine "$@"
