import SwiftUI

public struct QuickToolsHUDView: View {
    @ObservedObject private var ocr = ScreenOCREngine.shared
    @ObservedObject private var colorPicker = ColorPickerEngine.shared
    @ObservedObject private var keepAwake = KeepAwakeEngine.shared
    @ObservedObject private var portManager = PortManagerEngine.shared
    @ObservedObject private var toggles = QuickTogglesEngine.shared
    @ObservedObject private var cleaning = CleaningModeEngine.shared
    
    @State private var selectedDuration: KeepAwakeEngine.PresetDuration = .indefinite
    @State private var showingPorts: Bool = false
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Top Utilities Grid
                HStack(spacing: 12) {
                    // OCR Card
                    Button(action: {
                        ApexHUDWindowController.shared.hide()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            ScreenOCREngine.shared.startInteractiveOCR()
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "text.viewfinder")
                                .font(.system(size: 22))
                                .foregroundColor(.apexCyan)
                            Text("Screen OCR")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Text("Snip & Copy Text")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.apexCyan.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    
                    // Color Picker Card
                    Button(action: {
                        ApexHUDWindowController.shared.hide()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            ColorPickerEngine.shared.pickColor()
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "eyedropper.halffull")
                                .font(.system(size: 22))
                                .foregroundColor(.apexPurple)
                            Text("Color Picker")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Text(colorPicker.lastHexValue ?? "Sample HEX/RGB")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.apexPurple.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    
                    // Keyboard Cleaner Card
                    Button(action: {
                        ApexHUDWindowController.shared.hide()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            CleaningModeEngine.shared.start()
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 22))
                                .foregroundColor(.apexEmerald)
                            Text("Cleaning Mode")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Text("Lock Keyboard")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.apexEmerald.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                
                // Caffeine Keep Awake Row
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "cup.and.saucer.fill")
                            .foregroundColor(.orange)
                        Text("Keep Awake (Caffeine)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { keepAwake.isActive },
                            set: { _ in keepAwake.toggle(duration: selectedDuration) }
                        ))
                        .toggleStyle(.switch)
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(KeepAwakeEngine.PresetDuration.allCases) { preset in
                            Button(action: {
                                selectedDuration = preset
                                if keepAwake.isActive {
                                    keepAwake.activate(duration: preset)
                                }
                            }) {
                                Text(preset.title)
                                    .font(.system(size: 10, weight: selectedDuration == preset ? .bold : .regular))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(selectedDuration == preset ? Color.orange.opacity(0.3) : Color.white.opacity(0.05))
                                    .foregroundColor(selectedDuration == preset ? .orange : .gray)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    if let remaining = keepAwake.remainingSeconds {
                        Text("Awake remaining: \(remaining / 60)m \(remaining % 60)s")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
                
                // Quick System Toggles
                VStack(alignment: .leading, spacing: 10) {
                    Text("System Toggles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Button(action: { toggles.toggleHiddenFiles() }) {
                            HStack(spacing: 6) {
                                Image(systemName: toggles.showHiddenFiles ? "eye.fill" : "eye.slash.fill")
                                Text(toggles.showHiddenFiles ? "Hidden: ON" : "Hidden: OFF")
                                    .font(.system(size: 11))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { toggles.toggleDesktopIcons() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "menubar.dock.rectangle")
                                Text(toggles.showDesktopIcons ? "Desktop Icons" : "Clean Desktop")
                                    .font(.system(size: 11))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { toggles.flushDNS() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                Text("Flush DNS")
                                    .font(.system(size: 11))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
                
                // Active Port Manager
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.apexCyan)
                        Text("Active Listening Ports (\(portManager.entries.count))")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        
                        Button(action: { portManager.refresh() }) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.apexCyan)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if portManager.entries.isEmpty {
                        Button(action: { portManager.refresh() }) {
                            Text("Scan Open Ports")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.apexCyan)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(Color.apexCyan.opacity(0.1))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    } else {
                        VStack(spacing: 6) {
                            ForEach(portManager.entries.prefix(6)) { entry in
                                HStack {
                                    Text(":\(entry.port)")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.apexCyan)
                                        .frame(width: 55, alignment: .leading)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.command)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("PID \(entry.pid) • \(entry.address)")
                                            .font(.system(size: 9))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        portManager.terminateProcess(pid: entry.pid)
                                    }) {
                                        Text("Kill")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.red.opacity(0.15))
                                            .cornerRadius(4)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.02))
                                .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
            }
            .padding(16)
        }
    }
}
