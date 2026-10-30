import SwiftUI

public struct PeripheralInputHUDView: View {
    @ObservedObject private var inverter = ScrollInverterEngine.shared
    @ObservedObject private var nav = MouseNavigationEngine.shared
    @ObservedObject private var module = ApexKernel.shared.peripheralInput
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Scroll Direction Inverter Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(.apexCyan)
                        Text("Independent Scroll Inversion")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { module.scrollInverterEnabled },
                            set: { module.scrollInverterEnabled = $0 }
                        ))
                        .toggleStyle(.switch)
                    }
                    
                    Text("Invert external mouse wheel scroll direction without affecting macOS natural trackpad scrolling.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    
                    if module.scrollInverterEnabled {
                        HStack(spacing: 12) {
                            Toggle("Invert Vertical", isOn: Binding(
                                get: { inverter.invertVertical },
                                set: { inverter.invertVertical = $0 }
                            ))
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                            
                            Toggle("Invert Horizontal", isOn: Binding(
                                get: { inverter.invertHorizontal },
                                set: { inverter.invertHorizontal = $0 }
                            ))
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
                
                // SuperKey (Hyper Key) Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "command.circle.fill")
                            .foregroundColor(.apexPurple)
                        Text("SuperKey (Hyper Key)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { module.superKeyHyperEnabled },
                            set: { module.superKeyHyperEnabled = $0 }
                        ))
                        .toggleStyle(.switch)
                    }
                    
                    Text("Remap the useless CapsLock key to ⌃⌥⌘⇧ (Hyper Key) for ultimate window and app shortcuts.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                .padding(14)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
                
                // Mouse Side Buttons Navigation Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(.apexEmerald)
                        Text("Mouse Side Navigation")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { module.sideButtonsNavigationEnabled },
                            set: { module.sideButtonsNavigationEnabled = $0 }
                        ))
                        .toggleStyle(.switch)
                    }
                    
                    Text("Map mouse buttons 4 and 5 to system Back (⌘[) and Forward (⌘]) in Chrome, Safari, and Finder.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                .padding(14)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
            }
            .padding(16)
        }
    }
}
