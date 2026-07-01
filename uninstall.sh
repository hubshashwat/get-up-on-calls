#!/usr/bin/env bash
# ============================================================================
#  uninstall.sh — Remove mic-monitor LaunchAgent
# ============================================================================

set -euo pipefail

PLIST_NAME="com.standup.micmonitor.plist"
PLIST_DST="$HOME/Library/LaunchAgents/${PLIST_NAME}"
LOG_FILE="$HOME/Library/Logs/mic-monitor.log"

echo "🧍 Stand-Up-On-Calls — Uninstaller"
echo "===================================="
echo ""

# 1. Unload the LaunchAgent
if launchctl print "gui/$(id -u)/${PLIST_NAME}" &>/dev/null; then
    launchctl bootout "gui/$(id -u)/${PLIST_NAME}" 2>/dev/null || true
    echo "✅ LaunchAgent unloaded"
else
    echo "ℹ️  LaunchAgent was not loaded"
fi

# 2. Remove the plist
if [[ -f "$PLIST_DST" ]]; then
    rm "$PLIST_DST"
    echo "✅ Removed ${PLIST_DST}"
else
    echo "ℹ️  Plist not found at ${PLIST_DST}"
fi

# 3. Optionally remove log file
if [[ -f "$LOG_FILE" ]]; then
    read -rp "🗑  Remove log file at ${LOG_FILE}? [y/N] " answer
    if [[ "${answer,,}" == "y" ]]; then
        rm "$LOG_FILE"
        echo "✅ Log file removed"
    else
        echo "ℹ️  Log file kept"
    fi
fi

echo ""
echo "🎉 Mic Monitor has been uninstalled."
