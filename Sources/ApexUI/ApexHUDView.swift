import SwiftUI

public struct ApexHUDView: View {
    @State private var selectedTab: ApexTab = .overview
    @ObservedObject private var cpu = CPUStatsEngine.shared
    @ObservedObject private var memory = MemoryStatsEngine.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Luxury Header Bar
            HStack(spacing: 10) {
                // Crest Mark
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.apexCyan.opacity(0.25), Color.apexPurple.opacity(0.25)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.apexCyan.opacity(0.4), lineWidth: 1)
                        )
                    
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.apexCyan, .white],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text("APEX")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .tracking(0.8)
                            .foregroundColor(.white)
                        
                        Text("v1.0")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.apexTextTertiary)
                    }
                    
                    Text("Apple Silicon Native Toolkit")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.apexTextSecondary)
                }
                
                Spacer()
                
                // Micro Pulse Chip
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.apexEmerald)
                        .frame(width: 5, height: 5)
                        .shadow(color: Color.apexEmerald.opacity(0.8), radius: 3)
                    
                    Text("0.0% CPU")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.apexEmerald)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.apexEmerald.opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.apexEmerald.opacity(0.25), lineWidth: 0.8))
                
                // Close Button
                Button(action: {
                    ApexHUDWindowController.shared.hide()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.apexTextSecondary)
                        .frame(width: 22, height: 22)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)
            .background(Color.black.opacity(0.35))
            
            // Refined Segmented Tab Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(ApexTab.allCases) { tab in
                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                selectedTab = tab
                            }
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 11, weight: selectedTab == tab ? .bold : .regular))
                                Text(tab.rawValue)
                                    .font(.system(size: 11, weight: selectedTab == tab ? .semibold : .medium))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                ZStack {
                                    if selectedTab == tab {
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.apexCyan.opacity(0.22), Color.apexCyan.opacity(0.10)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                                    .stroke(Color.apexCyan.opacity(0.45), lineWidth: 1)
                                            )
                                    } else {
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .fill(Color.white.opacity(0.03))
                                    }
                                }
                            )
                            .foregroundColor(selectedTab == tab ? .white : .apexTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(Color.black.opacity(0.20))
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // Tab Content Frame
            Group {
                switch selectedTab {
                case .overview:
                    OverviewView { tab in
                        selectedTab = tab
                    }
                case .tools:
                    QuickToolsHUDView()
                case .peripherals:
                    PeripheralInputHUDView()
                case .snapping:
                    WindowGridHUDView()
                case .mixer:
                    VolumeMixerHUDView()
                case .stats:
                    SystemStatsHUDView()
                case .cleaner:
                    AppCleanerHUDView()
                case .clipboard:
                    ClipboardHUDView()
                case .shield:
                    BiometricShieldHUDView()
                case .settings:
                    SettingsHUDView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom Footer Status Bar
            Divider()
                .background(Color.white.opacity(0.08))
            
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "memorychip")
                        .font(.system(size: 10))
                        .foregroundColor(.apexPurple)
                    Text(String(format: "%.1f GB Unified RAM", memory.memory.usedGB))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.apexTextSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    selectedTab = .settings
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 10))
                        Text("Module Manager")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.apexCyan)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.35))
        }
        .frame(width: 470, height: 610)
        .background(
            ZStack {
                // High quality backdrop blur
                VisualEffectBackgroundView(material: .underWindowBackground, blendingMode: .behindWindow)
                // Dark obsidian glass tint layer
                Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.86)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.24), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.45), radius: 25, x: 0, y: 15)
    }
}
