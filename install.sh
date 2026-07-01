#!/usr/bin/env bash
# ============================================================================
#  install.sh — Set up mic-monitor as a LaunchAgent (auto-start on login)
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_NAME="com.getup.micmonitor.plist"
PLIST_SRC="${SCRIPT_DIR}/${PLIST_NAME}"
PLIST_DST="$HOME/Library/LaunchAgents/${PLIST_NAME}"
MIC_SCRIPT="${SCRIPT_DIR}/mic_monitor.sh"
LOG_DIR="$HOME/Library/Logs"

echo "🧍 Get-Up-On-Calls — Installer"
echo "============================="
echo ""

# 1. Ensure mic_monitor.sh is executable
chmod +x "$MIC_SCRIPT"
echo "✅ Made mic_monitor.sh executable"

# 2. Create LaunchAgents directory if it doesn't exist
mkdir -p "$HOME/Library/LaunchAgents"

# 3. Generate the plist with correct paths
sed \
    -e "s|MIC_MONITOR_PATH_PLACEHOLDER|${MIC_SCRIPT}|g" \
    -e "s|LOG_PATH_PLACEHOLDER|${LOG_DIR}|g" \
    "$PLIST_SRC" > "$PLIST_DST"
echo "✅ Installed plist to ${PLIST_DST}"

# 4. Unload if already loaded (ignore errors)
launchctl bootout "gui/$(id -u)/${PLIST_NAME}" 2>/dev/null || true

# 5. Load the LaunchAgent
launchctl bootstrap "gui/$(id -u)" "$PLIST_DST"
echo "✅ LaunchAgent loaded"

# 6. Verify
sleep 1
if launchctl print "gui/$(id -u)/${PLIST_NAME}" &>/dev/null; then
    echo ""
    echo "🎉 Mic Monitor is running!"
    echo "   Logs: ${LOG_DIR}/mic-monitor.log"
    echo ""
    echo "   To stop:    launchctl bootout gui/$(id -u)/${PLIST_NAME}"
    echo "   To restart: launchctl kickstart -k gui/$(id -u)/${PLIST_NAME}"
    echo "   To remove:  ./uninstall.sh"
else
    echo ""
    echo "⚠️  LaunchAgent loaded but may not be running yet."
    echo "   Check: launchctl list | grep micmonitor"
    echo "   Logs:  ${LOG_DIR}/mic-monitor.log"
fi
