#!/usr/bin/env bash
# ============================================================================
#  mic_monitor.sh — Stand Up On Calls
#  Detects when your Mac's microphone goes active and sends a notification
#  reminding you to get up and go to your standing desk.
#
#  Works on Apple Silicon (M1/M2/M3/M4/M5) and Intel Macs.
#  Uses a compiled Swift binary (mic_check) that queries CoreAudio directly.
# ============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
#  🎛  CONFIGURATION — Customize these to your liking
# ---------------------------------------------------------------------------

# How often to check microphone state (in seconds)
POLL_INTERVAL=5

# Notification message
NOTIFY_TITLE="🧍 Stand Up!"
NOTIFY_MESSAGE="You're on a call — get to your standing desk!"

# macOS notification sound (from /System/Library/Sounds/)
# Options: Basso, Blow, Bottle, Frog, Funk, Glass, Hero, Morse, Ping, Pop,
#          Purr, Sosumi, Submarine, Tink
# Set to "" for silent notifications
NOTIFY_SOUND="Hero"

# Cooldown after a call ends before a new notification can fire (seconds).
# Prevents spam from rapid mic toggling (mute/unmute).
COOLDOWN_SECONDS=10

# ---------------------------------------------------------------------------
#  🔧  INTERNALS — No need to edit below this line
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIC_CHECK="${SCRIPT_DIR}/mic_check"

STATE="IDLE"            # IDLE or ON_CALL
LAST_CALL_END=0         # timestamp of last call end (for cooldown)

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Check if the mic_check binary exists; compile if needed
ensure_mic_check() {
    if [[ ! -x "$MIC_CHECK" ]]; then
        log "⚙️  mic_check binary not found, compiling..."
        if swiftc -o "$MIC_CHECK" "${SCRIPT_DIR}/mic_check.swift" 2>/dev/null; then
            chmod +x "$MIC_CHECK"
            log "   ✅ Compiled successfully"
        else
            log "   ❌ Failed to compile mic_check.swift"
            log "   Make sure Xcode Command Line Tools are installed:"
            log "   xcode-select --install"
            exit 1
        fi
    fi
}

# Check if the default audio input device is currently running.
# Returns 0 (true) if active, 1 (false) if idle.
is_mic_active() {
    "$MIC_CHECK" &>/dev/null
    return $?
}

# Send a macOS notification via osascript
send_notification() {
    local sound_clause=""
    if [[ -n "$NOTIFY_SOUND" ]]; then
        sound_clause="sound name \"$NOTIFY_SOUND\""
    fi

    osascript -e "display notification \"$NOTIFY_MESSAGE\" with title \"$NOTIFY_TITLE\" $sound_clause" 2>/dev/null || true
}

# Get current epoch time
now() {
    date +%s
}

# ---------------------------------------------------------------------------
#  🏃  MAIN LOOP
# ---------------------------------------------------------------------------

ensure_mic_check

log "🎙  Mic Monitor started (polling every ${POLL_INTERVAL}s)"
log "   State: $STATE"

while true; do
    if is_mic_active; then
        # Mic is active
        if [[ "$STATE" == "IDLE" ]]; then
            # Check cooldown
            local_now=$(now)
            elapsed=$(( local_now - LAST_CALL_END ))

            if (( elapsed >= COOLDOWN_SECONDS )); then
                STATE="ON_CALL"
                log "📞 Call detected! Sending notification..."
                send_notification
                log "   ✅ Notification sent"
            else
                log "   ⏳ Mic active but in cooldown (${elapsed}s / ${COOLDOWN_SECONDS}s)"
            fi
        fi
    else
        # Mic is idle
        if [[ "$STATE" == "ON_CALL" ]]; then
            STATE="IDLE"
            LAST_CALL_END=$(now)
            log "📴 Call ended"
        fi
    fi

    sleep "$POLL_INTERVAL"
done
