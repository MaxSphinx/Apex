import Foundation
import IOKit.pwr_mgt
import Combine

@MainActor
public final class KeepAwakeEngine: ObservableObject {
    public static let shared = KeepAwakeEngine()
    
    @Published public private(set) var isActive: Bool = false
    @Published public private(set) var remainingSeconds: Int? = nil
    @Published public var preventDisplaySleep: Bool = true
    
    private var assertionID: IOPMAssertionID = 0
    private var displayAssertionID: IOPMAssertionID = 0
    private var countdownTimer: Timer?
    
    public enum PresetDuration: Int, CaseIterable, Identifiable {
        case indefinite = 0
        case minutes15 = 900
        case minutes30 = 1800
        case hour1 = 3600
        case hours2 = 7200
        
        public var id: Int { rawValue }
        public var title: String {
            switch self {
            case .indefinite: return "Indefinitely"
            case .minutes15: return "15 Minutes"
            case .minutes30: return "30 Minutes"
            case .hour1: return "1 Hour"
            case .hours2: return "2 Hours"
            }
        }
    }
    
    private init() {}
    
    public func toggle(duration: PresetDuration = .indefinite) {
        if isActive {
            deactivate()
        } else {
            activate(duration: duration)
        }
    }
    
    public func activate(duration: PresetDuration = .indefinite) {
        deactivate()
        
        let reason = "Apex Keep Awake Session" as CFString
        let sysResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        
        if preventDisplaySleep {
            _ = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason,
                &displayAssertionID
            )
        }
        
        if sysResult == kIOReturnSuccess {
            isActive = true
            
            if duration != .indefinite {
                self.remainingSeconds = duration.rawValue
                
                countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    Task { @MainActor in
                        self?.tickCountdown()
                    }
                }
            } else {
                self.remainingSeconds = nil
            }
        }
    }
    
    private func tickCountdown() {
        guard let current = remainingSeconds else { return }
        let next = current - 1
        self.remainingSeconds = next
        if next <= 0 {
            deactivate()
        }
    }
    
    public func deactivate() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        remainingSeconds = nil
        
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
        if displayAssertionID != 0 {
            IOPMAssertionRelease(displayAssertionID)
            displayAssertionID = 0
        }
        
        isActive = false
    }
}
