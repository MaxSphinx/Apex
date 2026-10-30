import SwiftUI

public struct OverviewView: View {
    @ObservedObject private var cpu = CPUStatsEngine.shared
    @ObservedObject private var memory = MemoryStatsEngine.shared
    @ObservedObject private var audio = AudioEngine.shared
    @ObservedObject private var prefs = ApexPreferences.shared
    
    public var onSelectTab: (ApexTab) -> Void
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Top Status Hero Card
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.apexEmerald)
                                .frame(width: 8, height: 8)
                            Text("APEX Microkernel Active")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Text("Apple Silicon Native • Idle RAM < 18 MB")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("CPU LOAD")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.gray)
                            Text(String(format: "%.0f%%", cpu.cpuLoad.totalUsage))
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundColor(.apexCyan)
                        }
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("RAM USED")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.gray)
                            Text(String(format: "%.1f GB", memory.memory.usedGB))
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundColor(.apexPurple)
                        }
                    }
                }
                .padding(14)
                .glassCard(borderColor: Color.apexCyan.opacity(0.3))
                
                // Quick Action Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    // Quick Snap Tile
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "rectangle.split.2x2")
                                .foregroundColor(.apexCyan)
                            Text("Window Snap")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        HStack(spacing: 6) {
                            Button(action: { WindowEngine.shared.snapFocusedWindow(to: .leftHalf) }) {
                                Image(systemName: "rectangle.leadinghalf.filled")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: { WindowEngine.shared.snapFocusedWindow(to: .maximize) }) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: { WindowEngine.shared.snapFocusedWindow(to: .rightHalf) }) {
                                Image(systemName: "rectangle.trailinghalf.filled")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(12)
                    .glassCard()
                    
                    // Quick Audio Tile
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: audio.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .foregroundColor(audio.isMuted ? .apexCoral : .apexEmerald)
                            Text("Master Volume")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(Int(audio.masterVolume * 100))%")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        Slider(value: $audio.masterVolume, in: 0...1)
                            .accentColor(.apexCyan)
                    }
                    .padding(12)
                    .glassCard()
                    
                    // Quick Memory Purge Tile
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.yellow)
                            Text("Memory Purge")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        Button(action: { memory.purgeMemory() }) {
                            HStack {
                                if memory.isPurging {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(memory.isPurging ? "Purging..." : "Free Inactive RAM")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(Color.yellow.opacity(0.15))
                            .foregroundColor(.yellow)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .disabled(memory.isPurging)
                    }
                    .padding(12)
                    .glassCard()
                    
                    // Quick Shelf & Notch Toggle
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "tray.and.arrow.down.fill")
                                .foregroundColor(.apexPurple)
                            Text("Floating Shelf")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        Button(action: { ShelfWindowController.shared.toggle() }) {
                            Text(ShelfWindowController.shared.isVisible ? "Hide Drop Shelf" : "Show Drop Shelf")
                                .font(.system(size: 11, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(Color.apexPurple.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .glassCard()
                }
                
                // Feature Modules Direct Jump Row
                VStack(alignment: .leading, spacing: 10) {
                    Text("QUICK MODULE JUMP")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ModuleJumpButton(title: "Tools & OCR", icon: "wrench.and.screwdriver.fill", color: .apexCyan) {
                            onSelectTab(.tools)
                        }
                        ModuleJumpButton(title: "Mouse & Keys", icon: "computermouse.fill", color: .apexEmerald) {
                            onSelectTab(.peripherals)
                        }
                        ModuleJumpButton(title: "Audio Mixer", icon: "speaker.wave.3.fill", color: .apexPurple) {
                            onSelectTab(.mixer)
                        }
                        ModuleJumpButton(title: "App Cleaner", icon: "trash.fill", color: .apexCoral) {
                            onSelectTab(.cleaner)
                        }
                        ModuleJumpButton(title: "FaceLock", icon: "faceid", color: .apexCyan) {
                            onSelectTab(.shield)
                        }
                        ModuleJumpButton(title: "Clipboard", icon: "doc.on.clipboard.fill", color: .yellow) {
                            onSelectTab(.clipboard)
                        }
                    }
                }
                .padding(12)
                .glassCard()
            }
            .padding(16)
        }
    }
}

public struct ModuleJumpButton: View {
    public let title: String
    public let icon: String
    public let color: Color
    public let action: () -> Void
    
    public var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
