import SwiftUI

public struct ApexHUDView: View {
    @State private var selectedTab: ApexTab = .overview
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 8) {
                // Peak Icon
                HStack(spacing: 6) {
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.apexCyan)
                    Text("APEX")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Active status pill
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.apexEmerald)
                        .frame(width: 6, height: 6)
                    Text("ARM64")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.apexEmerald)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.apexEmerald.opacity(0.12))
                .cornerRadius(4)
                
                Button(action: {
                    ApexHUDWindowController.shared.hide()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.4))
            
            // Tab Selector Scroll / Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(ApexTab.allCases) { tab in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedTab = tab
                            }
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 11))
                                Text(tab.rawValue)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                selectedTab == tab ?
                                    Color.apexCyan.opacity(0.2) :
                                    Color.white.opacity(0.04)
                            )
                            .foregroundColor(selectedTab == tab ? .apexCyan : .gray)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedTab == tab ? Color.apexCyan.opacity(0.5) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .background(Color.black.opacity(0.2))
            
            Divider().background(Color.white.opacity(0.1))
            
            // Tab Content
            Group {
                switch selectedTab {
                case .overview:
                    OverviewView { tab in
                        selectedTab = tab
                    }
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
        }
        .frame(width: 480, height: 560)
        .background(
            VisualEffectBackgroundView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
    }
}
