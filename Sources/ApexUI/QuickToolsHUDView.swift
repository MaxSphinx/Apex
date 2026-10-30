import SwiftUI

public struct QuickToolsHUDView: View {
    @ObservedObject private var ocr = ScreenOCREngine.shared
    @ObservedObject private var colorPicker = ColorPickerEngine.shared
    @ObservedObject private var keepAwake = KeepAwakeEngine.shared
    @ObservedObject private var portManager = PortManagerEngine.shared
    @ObservedObject private var toggles = QuickTogglesEngine.shared
    @ObservedObject private var cleaning = CleaningModeEngine.shared
    
    @State private var selectedDuration: KeepAwakeEngine.PresetDuration = .indefinite
    @State private var portSearchText: String = ""
    @State private var dnsFlushed: Bool = false
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                // Section 1: Hero Instant Utilities (Linear/Raycast style)
                VStack(spacing: 8) {
                    // OCR Action Row
                    ToolActionRow(
                        icon: "text.viewfinder",
                        iconColor: .apexCyan,
                        title: "Screen OCR",
                        subtitle: ocr.lastRecognizedText != nil ? "Last: \"\(ocr.lastRecognizedText!.prefix(24))...\"" : "Snip any screen area to copy text",
                        actionTitle: ocr.isRecognizing ? "Snipping..." : "Snip Text",
                        actionColor: .apexCyan
                    ) {
                        ApexHUDWindowController.shared.hide()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            ScreenOCREngine.shared.startInteractiveOCR()
                        }
                    }
                    
                    // Color Sampler Action Row
                    ToolActionRow(
                        icon: "eyedropper.halffull",
                        iconColor: .apexPurple,
                        title: "Pixel Color Picker",
                        subtitle: colorPicker.lastHexValue ?? "Sample exact pixel color in HEX / RGB",
                        actionTitle: "Pick Color",
                        actionColor: .apexPurple,
                        colorBadge: colorPicker.lastSampledColor
                    ) {
                        ApexHUDWindowController.shared.hide()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            ColorPickerEngine.shared.pickColor()
                        }
                    }
                    
                    // Keyboard Cleaning Action Row
                    ToolActionRow(
                        icon: "sparkles",
                        iconColor: .apexEmerald,
                        title: "Keyboard Cleaner Lock",
                        subtitle: "Freeze keyboard inputs to safely wipe keys",
                        actionTitle: "Lock Keys",
                        actionColor: .apexEmerald
                    ) {
                        ApexHUDWindowController.shared.hide()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            CleaningModeEngine.shared.start()
                        }
                    }
                }
                
                // Section 2: Caffeine Keep-Awake Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.18))
                                .frame(width: 24, height: 24)
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                        }
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Caffeine Sleep Inhibitor")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            
                            if keepAwake.isActive, let remaining = keepAwake.remainingSeconds {
                                Text("Active • \(remaining / 60)m \(remaining % 60)s remaining")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(.orange)
                            } else if keepAwake.isActive {
                                Text("Active indefinitely")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.apexEmerald)
                            } else {
                                Text("Prevent system and display sleep")
                                    .font(.system(size: 10))
                                    .foregroundColor(.apexTextTertiary)
                            }
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { keepAwake.isActive },
                            set: { _ in keepAwake.toggle(duration: selectedDuration) }
                        ))
                        .toggleStyle(.switch)
                    }
                    
                    // Duration Segmented Selector
                    HStack(spacing: 5) {
                        ForEach(KeepAwakeEngine.PresetDuration.allCases) { preset in
                            Button(action: {
                                selectedDuration = preset
                                if keepAwake.isActive {
                                    keepAwake.activate(duration: preset)
                                }
                            }) {
                                Text(preset.title)
                                    .font(.system(size: 10, weight: selectedDuration == preset ? .bold : .medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 5)
                                    .background(
                                        selectedDuration == preset ?
                                            Color.orange.opacity(0.25) :
                                            Color.white.opacity(0.04)
                                    )
                                    .foregroundColor(selectedDuration == preset ? .orange : .apexTextSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(selectedDuration == preset ? Color.orange.opacity(0.4) : Color.clear, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(12)
                .luxuryGlass()
                
                // Section 3: System Quick Toggles
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "switch.2")
                            .font(.system(size: 11))
                            .foregroundColor(.apexCyan)
                        Text("SYSTEM TOGGLES")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.6)
                            .foregroundColor(.apexTextTertiary)
                        Spacer()
                    }
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        QuickToggleChip(
                            title: "Hidden Files",
                            icon: toggles.showHiddenFiles ? "eye.fill" : "eye.slash.fill",
                            isOn: toggles.showHiddenFiles
                        ) {
                            toggles.toggleHiddenFiles()
                        }
                        
                        QuickToggleChip(
                            title: "Desktop Icons",
                            icon: toggles.showDesktopIcons ? "menubar.dock.rectangle" : "rectangle.dashed",
                            isOn: toggles.showDesktopIcons
                        ) {
                            toggles.toggleDesktopIcons()
                        }
                        
                        QuickToggleChip(
                            title: "Dark Mode",
                            icon: toggles.isDarkMode ? "moon.stars.fill" : "sun.max.fill",
                            isOn: toggles.isDarkMode
                        ) {
                            toggles.toggleDarkMode()
                        }
                        
                        QuickToggleChip(
                            title: dnsFlushed ? "DNS Flushed ✓" : "Flush DNS Cache",
                            icon: "arrow.clockwise",
                            isOn: dnsFlushed
                        ) {
                            toggles.flushDNS()
                            dnsFlushed = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                dnsFlushed = false
                            }
                        }
                    }
                }
                .padding(12)
                .luxuryGlass()
                
                // Section 4: Live Port Manager & Process Killer
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "network")
                            .font(.system(size: 11))
                            .foregroundColor(.apexCyan)
                        Text("ACTIVE LISTENING PORTS")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.6)
                            .foregroundColor(.apexTextTertiary)
                        
                        Spacer()
                        
                        if portManager.isLoading {
                            ProgressView()
                                .controlSize(.mini)
                        } else {
                            Button(action: { portManager.refresh() }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 9))
                                    Text("Refresh")
                                        .font(.system(size: 9, weight: .semibold))
                                }
                                .foregroundColor(.apexCyan)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    if portManager.entries.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 6) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.apexEmerald)
                                Text("No unauthorized ports open")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.apexTextSecondary)
                            }
                            .padding(.vertical, 16)
                            Spacer()
                        }
                    } else {
                        VStack(spacing: 4) {
                            ForEach(portManager.entries.prefix(5)) { entry in
                                HStack(spacing: 8) {
                                    // Port Badge
                                    Text(":\(entry.port)")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(.apexCyan)
                                        .frame(width: 52, alignment: .leading)
                                    
                                    // Process Info
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(entry.command)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        
                                        Text("PID \(entry.pid) • \(entry.address)")
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(.apexTextTertiary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Instant Kill Button
                                    Button(action: {
                                        portManager.terminateProcess(pid: entry.pid)
                                    }) {
                                        Text("Kill")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.apexCoral)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.apexCoral.opacity(0.12))
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(Color.apexCoral.opacity(0.3), lineWidth: 0.8))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.02))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                    }
                }
                .padding(12)
                .luxuryGlass()
            }
            .padding(14)
        }
        .onAppear {
            if portManager.entries.isEmpty {
                portManager.refresh()
            }
        }
    }
}

// Subcomponent: Tool Action Row
private struct ToolActionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let actionTitle: String
    let actionColor: Color
    var colorBadge: NSColor? = nil
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon Badge
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(iconColor.opacity(0.14))
                    .frame(width: 32, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(iconColor.opacity(0.35), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(iconColor)
            }
            
            // Text Details
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    
                    if let color = colorBadge {
                        Circle()
                            .fill(Color(nsColor: color))
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 0.8))
                    }
                }
                
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.apexTextSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Action Trigger Pill
            Button(action: action) {
                Text(actionTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(
                            colors: [actionColor.opacity(0.4), actionColor.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(actionColor.opacity(0.5), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .luxuryGlass()
    }
}

// Subcomponent: Quick Toggle Chip
private struct QuickToggleChip: View {
    let title: String
    let icon: String
    let isOn: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(isOn ? .apexCyan : .apexTextTertiary)
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isOn ? .white : .apexTextSecondary)
                    .lineLimit(1)
                
                Spacer()
                
                Circle()
                    .fill(isOn ? Color.apexEmerald : Color.white.opacity(0.15))
                    .frame(width: 6, height: 6)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isOn ? Color.apexCyan.opacity(0.10) : Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isOn ? Color.apexCyan.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
