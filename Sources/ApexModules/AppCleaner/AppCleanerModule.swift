import Foundation
import Combine

@MainActor
public final class AppCleanerModule: ApexModule {
    public let id: String = "app_cleaner"
    public let name: String = "App Cleaner & Deep Uninstaller"
    public let description: String = "Detects app leftovers, deep scans caches, prefs, containers and safely cleans them."
    public let iconName: String = "trash.fill"
    
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
        self.isEnabled = ApexPreferences.shared.isModuleEnabled(named: "app_cleaner")
    }
    
    public func start() {
        guard isEnabled else { return }
        AppScanner.shared.scan()
    }
    
    public func stop() {
    }
}
