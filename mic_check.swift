// mic_check.swift — Checks if the default audio input device is currently running
// Uses CoreAudio's kAudioDevicePropertyDeviceIsRunningSomewhere property
// which is the most reliable way to detect mic usage on Apple Silicon Macs.
//
// Exit codes:
//   0 = microphone IS active
//   1 = microphone is NOT active
//   2 = error (no input device found, etc.)
//
// Usage: swift mic_check.swift  (or compile with: swiftc -o mic_check mic_check.swift)

import CoreAudio
import Foundation

/// Get the default audio input device ID
func getDefaultInputDevice() -> AudioDeviceID? {
    var deviceID = AudioDeviceID(0)
    var size = UInt32(MemoryLayout<AudioDeviceID>.size)

    var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultInputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    let status = AudioObjectGetPropertyData(
        AudioObjectID(kAudioObjectSystemObject),
        &address,
        0,
        nil,
        &size,
        &deviceID
    )

    if status != noErr || deviceID == kAudioObjectUnknown {
        return nil
    }

    return deviceID
}

/// Check if an audio device is running somewhere (any process)
func isDeviceRunningSomewhere(_ deviceID: AudioDeviceID) -> Bool {
    var isRunning: UInt32 = 0
    var size = UInt32(MemoryLayout<UInt32>.size)

    var address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
        mScope: kAudioObjectPropertyScopeInput,
        mElement: kAudioObjectPropertyElementMain
    )

    let status = AudioObjectGetPropertyData(
        deviceID,
        &address,
        0,
        nil,
        &size,
        &isRunning
    )

    if status != noErr {
        return false
    }

    return isRunning != 0
}

// Main
guard let inputDevice = getDefaultInputDevice() else {
    fputs("error: no default audio input device found\n", stderr)
    exit(2)
}

if isDeviceRunningSomewhere(inputDevice) {
    print("active")
    exit(0)
} else {
    print("idle")
    exit(1)
}
