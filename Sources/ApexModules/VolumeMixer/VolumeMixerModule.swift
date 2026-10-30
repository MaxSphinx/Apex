import Foundation
import Combine

@MainActor
public final class VolumeMixerModule: ApexModule {
    public let id: String = "volume_mixer"
    public let name: String = "Volume Mixer"
    public let description: String = "Per-app volume levels, quick mute, and CoreAudio output device switcher."
    public let iconName: String = "speaker.wave.3.fill"
    
    @Published public var isEnabled: Bool {
        didSet {
            ApexPreferences.shared.setModuleEnabled(named: id, enabled: isEnabled)
            if isEnabled {
                start()
            } else {
                stop()
            }
        }
    }
    
    private var timer: Timer?
    
    public init() {
        self.isEnabled = ApexPreferences.shared.isModuleEnabled(named: "volume_mixer")
    }
    
    public func start() {
        guard isEnabled else { return }
        AudioEngine.shared.refresh()
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            Task { @MainActor in
                AudioEngine.shared.refreshMasterVolume()
            }
        }
    }
    
    public func stop() {
        timer?.invalidate()
        timer = nil
    }
}
