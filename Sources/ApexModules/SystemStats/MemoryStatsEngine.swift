import Foundation
import Darwin

public struct MemoryData: Sendable {
    public var totalGB: Double
    public var usedGB: Double
    public var freeGB: Double
    public var activeGB: Double
    public var wiredGB: Double
    public var compressedGB: Double
    public var usagePercentage: Double {
        guard totalGB > 0 else { return 0 }
        return (usedGB / totalGB) * 100.0
    }
}

@MainActor
public final class MemoryStatsEngine: ObservableObject {
    public static let shared = MemoryStatsEngine()
    
    @Published public private(set) var memory: MemoryData = MemoryData(
        totalGB: 16.0,
        usedGB: 8.0,
        freeGB: 8.0,
        activeGB: 4.0,
        wiredGB: 2.0,
        compressedGB: 2.0
    )
    @Published public private(set) var isPurging: Bool = false
    
    private var timer: Timer?
    
    private init() {
        sample()
    }
    
    public func start() {
        stop()
        sample()
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
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
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var vmStats = vm_statistics64()
        
        let result = withUnsafeMutablePointer(to: &vmStats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return }
        
        let pageSize = UInt64(getpagesize())
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        
        let activeBytes = UInt64(vmStats.active_count) * pageSize
        let wiredBytes = UInt64(vmStats.wire_count) * pageSize
        let compressedBytes = UInt64(vmStats.compressor_page_count) * pageSize
        let freeBytes = UInt64(vmStats.free_count) * pageSize
        let inactiveBytes = UInt64(vmStats.inactive_count) * pageSize
        
        let usedBytes = activeBytes + wiredBytes + compressedBytes
        let gigabyte = 1024.0 * 1024.0 * 1024.0
        
        let data = MemoryData(
            totalGB: Double(totalBytes) / gigabyte,
            usedGB: Double(usedBytes) / gigabyte,
            freeGB: Double(freeBytes + inactiveBytes) / gigabyte,
            activeGB: Double(activeBytes) / gigabyte,
            wiredGB: Double(wiredBytes) / gigabyte,
            compressedGB: Double(compressedBytes) / gigabyte
        )
        
        self.memory = data
    }
    
    public func purgeMemory(completion: (@MainActor () -> Void)? = nil) {
        isPurging = true
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/sbin/purge")
            try? task.run()
            task.waitUntilExit()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Task { @MainActor in
                    self.sample()
                    self.isPurging = false
                    completion?()
                }
            }
        }
    }
}
