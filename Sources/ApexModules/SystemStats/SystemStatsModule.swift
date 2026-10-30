import Foundation
import Combine

@MainActor
public final class SystemStatsModule: ApexModule {
    public let id: String = "system_stats"
    public let name: String = "System & Notch Stats"
    public let description: String = "Live Apple Silicon CPU load, unified memory breakdown, and Notch Bar HUD."
    public let iconName: String = "gauge.with.needle.fill"
    
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
    
    public init() {
        self.isEnabled = ApexPreferences.shared.isModuleEnabled(named: "system_stats")
    }
    
    public func start() {
        guard isEnabled else { return }
        CPUStatsEngine.shared.start()
        MemoryStatsEngine.shared.start()
        BatteryStatsEngine.shared.start()
        
        if ApexPreferences.shared.notchBarEnabled {
            NotchBarController.shared.show()
        }
    }
    
    public func stop() {
        CPUStatsEngine.shared.stop()
        MemoryStatsEngine.shared.stop()
        BatteryStatsEngine.shared.stop()
        NotchBarController.shared.hide()
    }
}
