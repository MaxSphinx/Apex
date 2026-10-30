import Foundation
import Darwin

public struct CPULoadData: Sendable {
    public var user: Double
    public var system: Double
    public var idle: Double
    public var totalUsage: Double {
        return min(100.0, max(0.0, user + system))
    }
}

@MainActor
public final class CPUStatsEngine: ObservableObject {
    public static let shared = CPUStatsEngine()
    
    @Published public private(set) var cpuLoad: CPULoadData = CPULoadData(user: 0, system: 0, idle: 100)
    @Published public private(set) var history: [Double] = Array(repeating: 0, count: 24)
    @Published public private(set) var coreCount: Int = ProcessInfo.processInfo.activeProcessorCount
    
    private var previousInfo: processor_info_array_t?
    private var previousCount: mach_msg_type_number_t = 0
    private var timer: Timer?
    
    private init() {
        self.coreCount = ProcessInfo.processInfo.activeProcessorCount
        sample()
    }
    
    public func start() {
        stop()
        sample()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sample()
            }
        }
    }
    
    public func stop() {
        timer?.invalidate()
        timer = nil
        if let prev = previousInfo {
            let size = vm_size_t(previousCount) * vm_size_t(MemoryLayout<integer_t>.size)
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: prev)), size)
            previousInfo = nil
        }
    }
    
    public func sample() {
        var numCPUsU: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0
        
        let err = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUsU,
            &cpuInfo,
            &numCpuInfo
        )
        
        guard err == KERN_SUCCESS, let cpuInfo = cpuInfo else { return }
        
        if let prevInfo = previousInfo {
            var totalUser: UInt64 = 0
            var totalSystem: UInt64 = 0
            var totalIdle: UInt64 = 0
            var totalNice: UInt64 = 0
            
            let numCPUs = Int(numCPUsU)
            for i in 0..<numCPUs {
                let base = Int32(CPU_STATE_MAX) * Int32(i)
                let u = UInt64(cpuInfo[Int(base + CPU_STATE_USER)] - prevInfo[Int(base + CPU_STATE_USER)])
                let s = UInt64(cpuInfo[Int(base + CPU_STATE_SYSTEM)] - prevInfo[Int(base + CPU_STATE_SYSTEM)])
                let id = UInt64(cpuInfo[Int(base + CPU_STATE_IDLE)] - prevInfo[Int(base + CPU_STATE_IDLE)])
                let n = UInt64(cpuInfo[Int(base + CPU_STATE_NICE)] - prevInfo[Int(base + CPU_STATE_NICE)])
                
                totalUser += u
                totalSystem += s
                totalIdle += id
                totalNice += n
            }
            
            let totalTicks = totalUser + totalSystem + totalIdle + totalNice
            if totalTicks > 0 {
                let userPct = (Double(totalUser + totalNice) / Double(totalTicks)) * 100.0
                let sysPct = (Double(totalSystem) / Double(totalTicks)) * 100.0
                let idlePct = (Double(totalIdle) / Double(totalTicks)) * 100.0
                
                let load = CPULoadData(user: userPct, system: sysPct, idle: idlePct)
                self.cpuLoad = load
                self.history.append(load.totalUsage)
                if self.history.count > 24 {
                    self.history.removeFirst()
                }
            }
            
            let size = vm_size_t(previousCount) * vm_size_t(MemoryLayout<integer_t>.size)
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: prevInfo)), size)
        }
        
        previousInfo = cpuInfo
        previousCount = numCpuInfo
    }
}
