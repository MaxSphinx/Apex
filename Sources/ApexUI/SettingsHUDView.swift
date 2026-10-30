import SwiftUI

public struct SettingsHUDView: View {
    @ObservedObject private var prefs = ApexPreferences.shared
    @ObservedObject private var permissions = PermissionsManager.shared
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Microkernel Modules Management
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "cpu.fill")
                            .foregroundColor(.apexCyan)
                        Text("MICROKERNEL MODULE MANAGER")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                    }
                    
                    VStack(spacing: 8) {
                        ModuleToggleRow(
                            id: "window_snapping",
                            name: "Window Snapping & Grid",
                            icon: "rectangle.split.2x2",
                            desc: "Global hotkeys and snap matrix"
                        )
                        ModuleToggleRow(
                            id: "volume_mixer",
                            name: "Per-App Volume Mixer",
                            icon: "speaker.wave.3.fill",
                            desc: "CoreAudio stream management"
                        )
                        ModuleToggleRow(
                            id: "system_stats",
                            name: "System Stats & Notch Bar",
                            icon: "gauge.with.needle.fill",
                            desc: "Mach kernel CPU & unified RAM monitoring"
                        )
                        ModuleToggleRow(
                            id: "app_cleaner",
                            name: "App Cleaner & Deep Uninstaller",
                            icon: "trash.fill",
                            desc: "Cache, preference and container sweeper"
                        )
                        ModuleToggleRow(
                            id: "clipboard_history",
                            name: "Clipboard History",
                            icon: "doc.on.clipboard.fill",
                            desc: "Secure in-memory snippet manager"
                        )
                        ModuleToggleRow(
                            id: "file_shelf",
                            name: "File Drop Shelf",
                            icon: "tray.and.arrow.down.fill",
                            desc: "Floating cross-space parking panel"
                        )
                        ModuleToggleRow(
                            id: "biometric_shield",
                            name: "Biometric Shield (FaceLock)",
                            icon: "faceid",
                            desc: "Neural Engine camera verification"
                        )
                    }
                }
                .padding(14)
                .glassCard()
                
                // macOS Permissions Card
                VStack(alignment: .leading, spacing: 10) {
                    Text("SYSTEM PERMISSIONS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                    
                    HStack {
                        PermissionRow(
                            title: "Accessibility",
                            isGranted: permissions.isAccessibilityGranted,
                            onRequest: { permissions.requestAccessibility() }
                        )
                        PermissionRow(
                            title: "Camera (FaceLock)",
                            isGranted: permissions.isCameraGranted,
                            onRequest: { permissions.requestCamera { _ in } }
                        )
                        PermissionRow(
                            title: "Notifications",
                            isGranted: permissions.isNotificationGranted,
                            onRequest: { permissions.requestNotifications() }
                        )
                    }
                }
                .padding(14)
                .glassCard()
                
                // About APEX Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("APEX macOS Toolkit")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("v1.0.0 (arm64)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    
                    Text("The open-source, microkernel alternative to bloated toolkits. Built with Swift 6, AppKit & SwiftUI on Apple Silicon. Licensed under MIT.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    HStack {
                        Button(action: {
                            if let url = URL(string: "https://github.com/MaxSphinx/Apex") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("GitHub Repository")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button(action: { NSApplication.shared.terminate(nil) }) {
                            Text("Quit APEX")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.apexCoral)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
                .glassCard(borderColor: Color.apexCyan.opacity(0.3))
            }
            .padding(16)
        }
    }
}

public struct ModuleToggleRow: View {
    public let id: String
    public let name: String
    public let icon: String
    public let desc: String
    
    @State private var isEnabled: Bool = true
    
    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.apexCyan)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(.switch)
                .onChange(of: isEnabled) { _, newValue in
                    ApexPreferences.shared.setModuleEnabled(named: id, enabled: newValue)
                }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.04))
        .cornerRadius(8)
        .onAppear {
            self.isEnabled = ApexPreferences.shared.isModuleEnabled(named: id)
        }
    }
}

public struct PermissionRow: View {
    public let title: String
    public let isGranted: Bool
    public let onRequest: () -> Void
    
    public var body: some View {
        Button(action: onRequest) {
            VStack(spacing: 4) {
                Circle()
                    .fill(isGranted ? Color.apexEmerald : Color.apexCoral)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(isGranted ? "Granted" : "Grant")
                    .font(.system(size: 9))
                    .foregroundColor(isGranted ? .apexEmerald : .apexCoral)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.04))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
