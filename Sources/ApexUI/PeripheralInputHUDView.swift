import SwiftUI

public struct PeripheralInputHUDView: View {
    @ObservedObject private var inverter = ScrollInverterEngine.shared
    @ObservedObject private var nav = MouseNavigationEngine.shared
    @ObservedObject private var module = ApexKernel.shared.peripheralInput
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                // Scroll Direction Inverter Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color.apexCyan.opacity(0.14))
                                .frame(width: 32, height: 32)
                                .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(Color.apexCyan.opacity(0.35), lineWidth: 1))
                            
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.apexCyan)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Independent Scroll Inverter")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Reverse mouse wheel without affecting trackpad natural scrolling")
                                .font(.system(size: 10))
                                .foregroundColor(.apexTextSecondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { module.scrollInverterEnabled },
                            set: { module.scrollInverterEnabled = $0 }
                        ))
                        .toggleStyle(.switch)
                    }
                    
                    if module.scrollInverterEnabled {
                        Divider().background(Color.white.opacity(0.06))
                        
                        HStack(spacing: 16) {
                            Toggle("Invert Vertical", isOn: Binding(
                                get: { inverter.invertVertical },
                                set: { inverter.invertVertical = $0 }
                            ))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            
                            Toggle("Invert Horizontal", isOn: Binding(
                                get: { inverter.invertHorizontal },
                                set: { inverter.invertHorizontal = $0 }
                            ))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(12)
                .luxuryGlass()
                
                // SuperKey (Hyper Key) Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color.apexPurple.opacity(0.14))
                                .frame(width: 32, height: 32)
                                .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(Color.apexPurple.opacity(0.35), lineWidth: 1))
                            
                            Image(systemName: "command.circle.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.apexPurple)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SuperKey (Hyper Key)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Remap CapsLock to ⌃⌥⌘⇧ for frictionless shortcuts")
                                .font(.system(size: 10))
                                .foregroundColor(.apexTextSecondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { module.superKeyHyperEnabled },
                            set: { module.superKeyHyperEnabled = $0 }
                        ))
                        .toggleStyle(.switch)
                    }
                }
                .padding(12)
                .luxuryGlass()
                
                // Mouse Side Buttons Navigation Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color.apexEmerald.opacity(0.14))
                                .frame(width: 32, height: 32)
                                .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(Color.apexEmerald.opacity(0.35), lineWidth: 1))
                            
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.apexEmerald)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Side Buttons Navigation")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Buttons 4 & 5 navigate Back (⌘[) and Forward (⌘])")
                                .font(.system(size: 10))
                                .foregroundColor(.apexTextSecondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { module.sideButtonsNavigationEnabled },
                            set: { module.sideButtonsNavigationEnabled = $0 }
                        ))
                        .toggleStyle(.switch)
                    }
                }
                .padding(12)
                .luxuryGlass()
            }
            .padding(14)
        }
    }
}
