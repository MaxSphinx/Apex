import Foundation
import AppKit
import Combine

@MainActor
public final class QuickToolsModule: ApexModule {
    public let id: String = "quick_tools"
    public let name: String = "Quick Tools & OCR"
    public let description: String = "Offline OCR, pixel color picker, active port manager, cleaning lock, and URL stripper."
    public let iconName: String = "wrench.and.screwdriver.fill"
    
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
    
    @Published public var urlCleanerEnabled: Bool = true {
        didSet {
            if urlCleanerEnabled && isEnabled {
                URLCleanerEngine.shared.start()
            } else {
                URLCleanerEngine.shared.stop()
            }
        }
    }
    
    public init() {
        self.isEnabled = ApexPreferences.shared.isModuleEnabled(named: "quick_tools")
    }
    
    public func start() {
        guard isEnabled else { return }
        if urlCleanerEnabled {
            URLCleanerEngine.shared.start()
        }
        QuickTogglesEngine.shared.refreshState()
    }
    
    public func stop() {
        URLCleanerEngine.shared.stop()
        CleaningModeEngine.shared.stop()
    }
}
