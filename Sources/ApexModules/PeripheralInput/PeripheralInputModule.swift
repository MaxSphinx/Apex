import Foundation
import AppKit
import Combine

@MainActor
public final class PeripheralInputModule: ApexModule {
    public let id: String = "peripheral_input"
    public let name: String = "Mouse & Keyboard"
    public let description: String = "Independent scroll direction inversion, smooth scrolling, and CapsLock HyperKey."
    public let iconName: String = "computermouse.fill"
    
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
    
    @Published public var scrollInverterEnabled: Bool = true {
        didSet {
            if scrollInverterEnabled && isEnabled {
                ScrollInverterEngine.shared.start()
            } else {
                ScrollInverterEngine.shared.stop()
            }
        }
    }
    
    @Published public var sideButtonsNavigationEnabled: Bool = true {
        didSet {
            MouseNavigationEngine.shared.enableSideButtonsNavigation = sideButtonsNavigationEnabled
            if sideButtonsNavigationEnabled && isEnabled {
                MouseNavigationEngine.shared.start()
            } else {
                MouseNavigationEngine.shared.stop()
            }
        }
    }
    
    @Published public var superKeyHyperEnabled: Bool = false {
        didSet {
            SuperKeyEngine.shared.setEnabled(superKeyHyperEnabled && isEnabled)
        }
    }
    
    public init() {
        self.isEnabled = ApexPreferences.shared.isModuleEnabled(named: "peripheral_input")
    }
    
    public func start() {
        guard isEnabled else { return }
        
        if scrollInverterEnabled {
            ScrollInverterEngine.shared.start()
        }
        if sideButtonsNavigationEnabled {
            MouseNavigationEngine.shared.start()
        }
        if superKeyHyperEnabled {
            SuperKeyEngine.shared.setEnabled(true)
        }
    }
    
    public func stop() {
        ScrollInverterEngine.shared.stop()
        MouseNavigationEngine.shared.stop()
        SuperKeyEngine.shared.setEnabled(false)
    }
}
