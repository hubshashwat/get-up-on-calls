# 🧍 Stand-Up-On-Calls

> Get a push notification to go to your standing desk every time you join a call.

A tiny macOS background utility that watches your microphone — when it goes active (Zoom, Meet, FaceTime, Slack, etc.), you get a notification with a sound:

**"🧍 Stand Up! You're on a call — get to your standing desk!"**

Works on **Apple Silicon** (M1/M2/M3/M4/M5) and Intel Macs. No apps to install. No dependencies beyond Xcode Command Line Tools.

---

## Setup on a New Mac

### Prerequisites

Make sure Xcode Command Line Tools are installed (needed to compile the Swift mic detector):

```bash
xcode-select --install
```

### Install

```bash
# 1. Clone the repo
git clone https://github.com/shashwatkumar/get-up-on-calls.git
cd get-up-on-calls

# 2. Run the installer (compiles Swift binary + sets up auto-start on login)
chmod +x install.sh
./install.sh

# 3. That's it! Join a call and watch for the notification 🎉
```

The installer will:
- Compile `mic_check.swift` → `mic_check` binary (first time only)
- Install a LaunchAgent so it runs automatically on every login
- Start monitoring immediately

> 💡 **Tip:** Avoid running this from protected macOS folders like `Desktop`, `Downloads`, or `Documents` as macOS may block script execution and binary generation. If you run into permission errors, move the project to a custom folder like `~/tools/` or `~/Developer/` and run it from there.

> **Note:** You may get a macOS prompt asking to allow notifications from **Script Editor** — say **Allow**.

## How It Works

```
┌─────────────┐    every 5s     ┌─────────────┐     call starts     ┌──────────────┐
│ mic_monitor │ ──────────────▸ │  mic_check   │ ──────────────────▸ │  macOS Push   │
│   (bash)    │                 │   (swift)    │                     │ Notification  │
└─────────────┘                 └─────────────┘                     └──────────────┘
      │                               │
      │  state machine                │  CoreAudio API
      │  IDLE ↔ ON_CALL               │  kAudioDevicePropertyDeviceIsRunningSomewhere
```

1. **`mic_check`** (compiled Swift) queries CoreAudio to check if the default audio input device is running
2. **`mic_monitor.sh`** (Bash) polls `mic_check` every 5 seconds and tracks state transitions
3. When the mic transitions from idle → active, it fires a macOS notification via `osascript`
4. It stays quiet for the rest of the call (no spam)
5. When the call ends and a new one starts, it notifies again
6. A 10-second cooldown prevents false triggers from mute/unmute toggling

## Customize

Edit the top of [`mic_monitor.sh`](mic_monitor.sh):

```bash
# How often to check (seconds)
POLL_INTERVAL=5

# Notification text
NOTIFY_TITLE="🧍 Stand Up!"
NOTIFY_MESSAGE="You're on a call — get to your standing desk!"

# Sound (from /System/Library/Sounds/)
# Options: Basso, Blow, Bottle, Frog, Funk, Glass, Hero, Morse,
#          Ping, Pop, Purr, Sosumi, Submarine, Tink
NOTIFY_SOUND="Hero"

# Cooldown after call ends before re-notifying (seconds)
COOLDOWN_SECONDS=10
```

After editing, restart the monitor:

```bash
launchctl kickstart -k "gui/$(id -u)/com.standup.micmonitor.plist"
```

## Manual Run (without LaunchAgent)

```bash
chmod +x mic_monitor.sh
./mic_monitor.sh
```

You'll see live logs in your terminal:

```
[2026-07-01 14:30:05] 🎙  Mic Monitor started (polling every 5s)
[2026-07-01 14:30:05]    State: IDLE
[2026-07-01 14:31:10] 📞 Call detected! Sending notification...
[2026-07-01 14:31:10]    ✅ Notification sent
[2026-07-01 14:45:32] 📴 Call ended
```

## Uninstall

```bash
./uninstall.sh
```

## Logs

When running as a LaunchAgent, logs are written to:

```
~/Library/Logs/mic-monitor.log
```

View live:
```bash
tail -f ~/Library/Logs/mic-monitor.log
```

## Troubleshooting

### Permission Denied or File Access Issues
- **macOS Protected Folder Block**: macOS heavily restricts script execution and binary compilation inside user folders like `Desktop`, `Downloads`, or `Documents`. If you hit permission errors, move the cloned repository to a directory outside of these (for example, create a folder in your home root like `~/tools/` or `~/Developer/` and move the repository there).
- **Executable Permission Denied**: If you get a permission denied error when running `./install.sh`, make sure it has executable permissions:
  ```bash
  chmod +x install.sh
  ```

### Notification doesn't appear
- Go to **System Settings → Notifications → Script Editor** and ensure notifications are enabled
- Make sure **Focus / Do Not Disturb** is off

### `mic_check` won't compile
- Install Xcode Command Line Tools: `xcode-select --install`
- The script auto-compiles `mic_check.swift` on first run

### LaunchAgent won't start
```bash
# Check status
launchctl print gui/$(id -u)/com.standup.micmonitor.plist

# Force restart
launchctl kickstart -k gui/$(id -u)/com.standup.micmonitor.plist

# View logs
cat ~/Library/Logs/mic-monitor.log
```

## Files

| File | Purpose |
|------|---------|
| `mic_check.swift` | Swift source — queries CoreAudio for mic status |
| `mic_check` | Compiled binary (auto-generated, git-ignored) |
| `mic_monitor.sh` | Core script — polls mic state, sends notifications |
| `com.standup.micmonitor.plist` | LaunchAgent template (paths filled in by install.sh) |
| `install.sh` | Sets up auto-start on login |
| `uninstall.sh` | Cleanly removes everything |

## Requirements

- macOS 12+ (Monterey or later)
- Xcode Command Line Tools (`xcode-select --install`)

## License

MIT — do whatever you want with it. 🧍

