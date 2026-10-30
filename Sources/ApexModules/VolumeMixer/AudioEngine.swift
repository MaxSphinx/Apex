import Foundation
import CoreAudio
import AudioToolbox
import AppKit

public struct AudioDevice: Identifiable, Hashable, Sendable {
    public let id: AudioDeviceID
    public let name: String
    public let uid: String
    public let isOutput: Bool
}

public struct AppAudioTarget: Identifiable, Hashable, @unchecked Sendable {
    public var id: String { bundleIdentifier }
    public let bundleIdentifier: String
    public let name: String
    public let icon: NSImage?
    public var volume: Float
    public var isMuted: Bool
}

@MainActor
public final class AudioEngine: ObservableObject {
    public static let shared = AudioEngine()
    
    @Published public private(set) var defaultOutputDeviceName: String = "Internal Speakers"
    @Published public var masterVolume: Float = 0.5 {
        didSet {
            setMasterVolume(masterVolume)
        }
    }
    @Published public var isMuted: Bool = false {
        didSet {
            setMasterMute(isMuted)
        }
    }
    @Published public private(set) var outputDevices: [AudioDevice] = []
    @Published public var appTargets: [AppAudioTarget] = []
    
    private var isUpdatingInternally = false
    
    private init() {
        refresh()
    }
    
    public func refresh() {
        refreshDevices()
        refreshMasterVolume()
        refreshAppTargets()
    }
    
    // MARK: - CoreAudio Device Queries
    
    private func getDefaultOutputDeviceID() -> AudioDeviceID? {
        var deviceID = kAudioObjectUnknown
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
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
        
        return status == noErr ? deviceID : nil
    }
    
    public func refreshDevices() {
        var size: UInt32 = 0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size
        )
        
        guard status == noErr else { return }
        let count = Int(size / UInt32(MemoryLayout<AudioDeviceID>.size))
        var deviceIDs = [AudioDeviceID](repeating: 0, count: count)
        
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceIDs
        )
        guard status == noErr else { return }
        
        var foundDevices: [AudioDevice] = []
        let currentDefault = getDefaultOutputDeviceID()
        
        for devID in deviceIDs {
            var streamSize: UInt32 = 0
            var streamAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreams,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            let streamStatus = AudioObjectGetPropertyDataSize(devID, &streamAddress, 0, nil, &streamSize)
            let isOutput = (streamStatus == noErr && streamSize > 0)
            guard isOutput else { continue }
            
            var nameSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
            var nameAddress = AudioObjectPropertyAddress(
                mSelector: kAudioObjectPropertyName,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var cfName: Unmanaged<CFString>?
            AudioObjectGetPropertyData(devID, &nameAddress, 0, nil, &nameSize, &cfName)
            let name = cfName?.takeRetainedValue() as String? ?? "Audio Device #\(devID)"
            
            var uidSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
            var uidAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceUID,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var cfUID: Unmanaged<CFString>?
            AudioObjectGetPropertyData(devID, &uidAddress, 0, nil, &uidSize, &cfUID)
            let uid = cfUID?.takeRetainedValue() as String? ?? "\(devID)"
            
            foundDevices.append(AudioDevice(id: devID, name: name, uid: uid, isOutput: true))
            
            if devID == currentDefault {
                self.defaultOutputDeviceName = name
            }
        }
        
        self.outputDevices = foundDevices
    }
    
    public func selectOutputDevice(_ device: AudioDevice) {
        var devID = device.id
        let size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            size,
            &devID
        )
        
        if status == noErr {
            defaultOutputDeviceName = device.name
            refreshMasterVolume()
        }
    }
    
    public func refreshMasterVolume() {
        guard let devID = getDefaultOutputDeviceID() else { return }
        
        var volume: Float32 = 0.5
        var size = UInt32(MemoryLayout<Float32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var status = AudioObjectGetPropertyData(devID, &address, 0, nil, &size, &volume)
        if status != noErr {
            address.mSelector = kAudioDevicePropertyVolumeScalar
            status = AudioObjectGetPropertyData(devID, &address, 0, nil, &size, &volume)
        }
        
        var mute: UInt32 = 0
        var muteSize = UInt32(MemoryLayout<UInt32>.size)
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectGetPropertyData(devID, &muteAddress, 0, nil, &muteSize, &mute)
        
        self.isUpdatingInternally = true
        if status == noErr {
            self.masterVolume = max(0.0, min(1.0, volume))
        }
        self.isMuted = (mute != 0)
        self.isUpdatingInternally = false
    }
    
    private func setMasterVolume(_ vol: Float) {
        guard !isUpdatingInternally, let devID = getDefaultOutputDeviceID() else { return }
        var targetVol = Float32(max(0.0, min(1.0, vol)))
        let size = UInt32(MemoryLayout<Float32>.size)
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var status = AudioObjectSetPropertyData(devID, &address, 0, nil, size, &targetVol)
        if status != noErr {
            address.mSelector = kAudioDevicePropertyVolumeScalar
            status = AudioObjectSetPropertyData(devID, &address, 0, nil, size, &targetVol)
        }
    }
    
    private func setMasterMute(_ mute: Bool) {
        guard !isUpdatingInternally, let devID = getDefaultOutputDeviceID() else { return }
        var muteVal: UInt32 = mute ? 1 : 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectSetPropertyData(devID, &address, 0, nil, size, &muteVal)
    }
    
    // MARK: - Per-App Audio Tracking
    
    public func refreshAppTargets() {
        let running = NSWorkspace.shared.runningApplications
        var targets: [AppAudioTarget] = []
        
        let knownMediaAppIDs: Set<String> = [
            "com.spotify.client",
            "com.apple.Music",
            "ru.keepcoder.Telegram",
            "com.google.Chrome",
            "company.thebrowser.Browser",
            "com.apple.Safari",
            "org.mozilla.firefox",
            "com.hnc.Discord",
            "com.tinyspeck.slackmacgap",
            "com.apple.QuickTimePlayerX",
            "com.apple.TV",
            "com.apple.Podcasts",
            "com.colliderli.iina"
        ]
        
        for app in running where app.activationPolicy == .regular {
            guard let bid = app.bundleIdentifier, let name = app.localizedName else { continue }
            
            let key = "apex.volume.app." + bid
            let existingVol = UserDefaults.standard.object(forKey: key) as? Float ?? 1.0
            let muteKey = "apex.mute.app." + bid
            let isMuted = UserDefaults.standard.bool(forKey: muteKey)
            
            let isPriorityMedia = knownMediaAppIDs.contains(bid)
            if isPriorityMedia || targets.count < 8 {
                let target = AppAudioTarget(
                    bundleIdentifier: bid,
                    name: name,
                    icon: app.icon,
                    volume: existingVol,
                    isMuted: isMuted
                )
                targets.append(target)
            }
        }
        
        self.appTargets = targets
    }
    
    public func setAppVolume(bundleIdentifier: String, volume: Float) {
        if let idx = appTargets.firstIndex(where: { $0.bundleIdentifier == bundleIdentifier }) {
            appTargets[idx].volume = volume
            UserDefaults.standard.set(volume, forKey: "apex.volume.app." + bundleIdentifier)
            applyAppVolumeControl(bundleIdentifier: bundleIdentifier, volume: volume)
        }
    }
    
    public func toggleAppMute(bundleIdentifier: String) {
        if let idx = appTargets.firstIndex(where: { $0.bundleIdentifier == bundleIdentifier }) {
            appTargets[idx].isMuted.toggle()
            let isMuted = appTargets[idx].isMuted
            UserDefaults.standard.set(isMuted, forKey: "apex.mute.app." + bundleIdentifier)
            let effectiveVolume = isMuted ? 0.0 : appTargets[idx].volume
            applyAppVolumeControl(bundleIdentifier: bundleIdentifier, volume: effectiveVolume)
        }
    }
    
    private func applyAppVolumeControl(bundleIdentifier: String, volume: Float) {
        let intVol = Int(max(0.0, min(1.0, volume)) * 100)
        
        switch bundleIdentifier {
        case "com.apple.Music":
            executeScript("tell application \"Music\" to set sound volume to \(intVol)")
            
        case "com.spotify.client":
            executeScript("tell application \"Spotify\" to set sound volume to \(intVol)")
            
        case "com.apple.QuickTimePlayerX":
            executeScript("tell application \"QuickTime Player\" to set audio volume of every document to \(Double(volume))")
            
        case "com.apple.TV":
            executeScript("tell application \"TV\" to set sound volume to \(intVol)")
            
        case "com.apple.Podcasts":
            executeScript("tell application \"Podcasts\" to set sound volume to \(intVol)")
            
        case "org.videolan.vlc":
            executeScript("tell application \"VLC\" to set volume to \(intVol * 2)")
            
        case "com.google.Chrome", "company.thebrowser.Browser", "com.brave.Browser":
            if volume <= 0.01 {
                executeScript("tell application id \"\(bundleIdentifier)\" to execute front window's active tab javascript \"document.querySelectorAll('video, audio').forEach(el => el.muted = true);\"")
            } else {
                let jsVol = String(format: "%.2f", volume)
                executeScript("tell application id \"\(bundleIdentifier)\" to execute front window's active tab javascript \"document.querySelectorAll('video, audio').forEach(el => { el.muted = false; el.volume = \(jsVol); });\"")
            }
            
        case "com.apple.Safari":
            if volume <= 0.01 {
                executeScript("tell application \"Safari\" to do JavaScript \"document.querySelectorAll('video, audio').forEach(el => el.muted = true);\" in current tab of front window")
            } else {
                let jsVol = String(format: "%.2f", volume)
                executeScript("tell application \"Safari\" to do JavaScript \"document.querySelectorAll('video, audio').forEach(el => { el.muted = false; el.volume = \(jsVol); });\" in current tab of front window")
            }
            
        default:
            break
        }
    }
    
    private func executeScript(_ source: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            if let script = NSAppleScript(source: source) {
                script.executeAndReturnError(&error)
            }
        }
    }
}
