import SwiftUI

public struct WindowGridHUDView: View {
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Halves Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("HALVES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 8) {
                        SnapActionCard(action: .leftHalf)
                        SnapActionCard(action: .rightHalf)
                        SnapActionCard(action: .topHalf)
                        SnapActionCard(action: .bottomHalf)
                    }
                }
                .padding(14)
                .glassCard()
                
                // Quarters Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("QUARTERS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        SnapActionCard(action: .topLeftQuarter)
                        SnapActionCard(action: .topRightQuarter)
                        SnapActionCard(action: .bottomLeftQuarter)
                        SnapActionCard(action: .bottomRightQuarter)
                    }
                }
                .padding(14)
                .glassCard()
                
                // Thirds & Utilities Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("THIRDS & SIZES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 8) {
                        SnapActionCard(action: .leftThird)
                        SnapActionCard(action: .centerThird)
                        SnapActionCard(action: .rightThird)
                    }
                    
                    HStack(spacing: 8) {
                        SnapActionCard(action: .maximize)
                        SnapActionCard(action: .center)
                    }
                }
                .padding(14)
                .glassCard()
                
                // Hotkey Cheatsheet
                HStack {
                    Image(systemName: "keyboard.fill")
                        .foregroundColor(.apexCyan)
                    Text("Use ⌃⌥ + Arrow keys or shortcuts directly in any app without opening menu.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                .padding(12)
                .glassCard()
            }
            .padding(16)
        }
    }
}

public struct SnapActionCard: View {
    public let action: WindowSnapAction
    
    public var body: some View {
        Button(action: {
            WindowEngine.shared.snapFocusedWindow(to: action)
        }) {
            VStack(spacing: 6) {
                Image(systemName: action.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(.apexCyan)
                Text(action.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                Text(action.shortcutDescription)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.04))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}
