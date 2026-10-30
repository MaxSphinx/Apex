import Foundation
import AppKit
import Combine

@MainActor
public final class DisplayPowerModule: ApexModule {
    public let id: String = "display_power"
    public let name: String = "Energy & Display"
    public let description: String = "Caffeine keep-awake sleep inhibitor and display brightness management."
    public let iconName: String = "bolt.fill"
    
    @Published public var isEnabled: Bool {
        didSet {
            ApexPreferences.shared.setModuleEnabled(named: id, enabled: isEnabled)
            if !isEnabled {
                stop()
            }
        }
    }
    
    public init() {
        self.isEnabled = ApexPreferences.shared.isModuleEnabled(named: "display_power")
    }
    
    public func start() {
        // Ready for keep-awake commands
    }
    
    public func stop() {
        KeepAwakeEngine.shared.deactivate()
    }
}
