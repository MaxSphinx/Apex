import Foundation
import IOKit.ps

public struct BatteryData: Sendable {
    public var hasBattery: Bool
    public var percentage: Int
    public var isCharging: Bool
    public var isACConnected: Bool
    public var timeRemainingMinutes: Int
    public var healthDescription: String
}

@MainActor
public final class BatteryStatsEngine: ObservableObject {
    public static let shared = BatteryStatsEngine()
    
    @Published public private(set) var battery: BatteryData = BatteryData(
        hasBattery: true,
        percentage: 100,
        isCharging: false,
        isACConnected: true,
        timeRemainingMinutes: 0,
        healthDescription: "Good"
    )
    
    private var timer: Timer?
    
    private init() {
        sample()
    }
    
    public func start() {
        stop()
        sample()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sample()
            }
        }
    }
    
    public func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    public func sample() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              !sources.isEmpty else {
            self.battery.hasBattery = false
            self.battery.isACConnected = true
            return
        }
        
        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            
            let currentCap = description[kIOPSCurrentCapacityKey as String] as? Int ?? 100
            let maxCap = description[kIOPSMaxCapacityKey as String] as? Int ?? 100
            let isCharging = description[kIOPSIsChargingKey as String] as? Bool ?? false
            let powerSourceState = description[kIOPSPowerSourceStateKey as String] as? String
            let isAC = (powerSourceState == kIOPSACPowerValue as String)
            let timeRemaining = description[kIOPSTimeToEmptyKey as String] as? Int ?? -1
            
            let pct = maxCap > 0 ? Int((Double(currentCap) / Double(maxCap)) * 100.0) : currentCap
            
            let data = BatteryData(
                hasBattery: true,
                percentage: max(0, min(100, pct)),
                isCharging: isCharging,
                isACConnected: isAC,
                timeRemainingMinutes: timeRemaining,
                healthDescription: "Optimal"
            )
            
            self.battery = data
            break
        }
    }
}
