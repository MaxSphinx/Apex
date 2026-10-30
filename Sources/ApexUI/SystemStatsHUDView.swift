import SwiftUI

public struct SystemStatsHUDView: View {
    @ObservedObject private var cpu = CPUStatsEngine.shared
    @ObservedObject private var memory = MemoryStatsEngine.shared
    @ObservedObject private var battery = BatteryStatsEngine.shared
    @ObservedObject private var prefs = ApexPreferences.shared
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // CPU Stats Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "cpu")
                            .foregroundColor(.apexCyan)
                        Text("APPLE SILICON CPU")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(cpu.coreCount) Active Cores")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    HStack(alignment: .bottom, spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(format: "%.1f%%", cpu.cpuLoad.totalUsage))
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundColor(.apexCyan)
                            Text("Total Load")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Mini Sparkline
                        HStack(alignment: .bottom, spacing: 3) {
                            ForEach(Array(cpu.history.enumerated()), id: \.offset) { _, val in
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(Color.apexCyan.opacity(0.75))
                                    .frame(width: 4, height: max(3, CGFloat(val) * 0.35))
                            }
                        }
                        .frame(height: 35, alignment: .bottom)
                    }
                    
                    // Detailed breakdown
                    HStack {
                        MetricPill(title: "User", value: String(format: "%.0f%%", cpu.cpuLoad.user), color: .apexCyan)
                        MetricPill(title: "System", value: String(format: "%.0f%%", cpu.cpuLoad.system), color: .apexPurple)
                        MetricPill(title: "Idle", value: String(format: "%.0f%%", cpu.cpuLoad.idle), color: .gray)
                    }
                }
                .padding(14)
                .glassCard(borderColor: Color.apexCyan.opacity(0.3))
                
                // Unified RAM Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "memorychip")
                            .foregroundColor(.apexPurple)
                        Text("UNIFIED MEMORY (RAM)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                        Spacer()
                        
                        Button(action: { memory.purgeMemory() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text(memory.isPurging ? "Purging..." : "Purge RAM")
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.yellow.opacity(0.2))
                            .foregroundColor(.yellow)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .disabled(memory.isPurging)
                    }
                    
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(format: "%.1f / %.0f GB", memory.memory.usedGB, memory.memory.totalGB))
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            Text(String(format: "%.0f%% Pressure Used", memory.memory.usagePercentage))
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    
                    // Visual Memory Bar
                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.apexPurple)
                                .frame(width: geo.size.width * CGFloat(memory.memory.wiredGB / memory.memory.totalGB))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.apexCyan)
                                .frame(width: geo.size.width * CGFloat(memory.memory.activeGB / memory.memory.totalGB))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.yellow.opacity(0.8))
                                .frame(width: geo.size.width * CGFloat(memory.memory.compressedGB / memory.memory.totalGB))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.1))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 8)
                    
                    HStack {
                        MetricPill(title: "Wired", value: String(format: "%.1f GB", memory.memory.wiredGB), color: .apexPurple)
                        MetricPill(title: "Active", value: String(format: "%.1f GB", memory.memory.activeGB), color: .apexCyan)
                        MetricPill(title: "Compressed", value: String(format: "%.1f GB", memory.memory.compressedGB), color: .yellow)
                        MetricPill(title: "Free", value: String(format: "%.1f GB", memory.memory.freeGB), color: .gray)
                    }
                }
                .padding(14)
                .glassCard(borderColor: Color.apexPurple.opacity(0.3))
                
                // Battery & Notch Row
                HStack(spacing: 12) {
                    // Battery Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: battery.battery.isCharging ? "battery.100.bolt" : "battery.100")
                                .foregroundColor(.apexEmerald)
                            Text("POWER & BATTERY")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.gray)
                        }
                        Text("\(battery.battery.percentage)%")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Text(battery.battery.isCharging ? "Charging (AC Adapter)" : (battery.battery.isACConnected ? "Power Adapter Connected" : "On Battery"))
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .glassCard()
                    
                    // Notch Bar Toggle Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "rectangle.topthird.inset.filled")
                                .foregroundColor(.apexCyan)
                            Text("NOTCH BAR HUD")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.gray)
                        }
                        Button(action: {
                            NotchBarController.shared.toggle()
                        }) {
                            Text(NotchBarController.shared.isVisible ? "Hide Notch Bar" : "Show Notch Bar")
                                .font(.system(size: 11, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.apexCyan.opacity(0.2))
                                .foregroundColor(.apexCyan)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .glassCard()
                }
            }
            .padding(16)
        }
    }
}

public struct MetricPill: View {
    public let title: String
    public let value: String
    public let color: Color
    
    public var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 9))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.04))
        .cornerRadius(6)
    }
}
