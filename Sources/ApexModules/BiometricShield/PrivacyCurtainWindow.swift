import Foundation
import AppKit
import SwiftUI
import LocalAuthentication

@MainActor
public final class PrivacyCurtainController: ObservableObject {
    public static let shared = PrivacyCurtainController()
    
    private var window: NSPanel?
    @Published public private(set) var isLocked: Bool = false
    @Published public private(set) var currentProtectedAppName: String = "Application"
    
    public var onUnlocked: (() -> Void)?
    
    private init() {}
    
    public func lock(appName: String, photo: NSImage? = nil) {
        guard !isLocked else { return }
        self.currentProtectedAppName = appName
        self.isLocked = true
        
        TelegramAlertEngine.shared.sendIntruderAlert(appName: appName, photo: photo)
        
        guard let screen = NSScreen.main else { return }
        
        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        let hosting = NSHostingView(rootView: PrivacyCurtainView())
        panel.contentView = hosting
        panel.makeKeyAndOrderFront(nil)
        
        self.window = panel
    }
    
    public func unlock() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock \(currentProtectedAppName)") { success, _ in
                Task { @MainActor in
                    if success {
                        self.dismiss()
                    }
                }
            }
        } else {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock \(currentProtectedAppName)") { success, _ in
                Task { @MainActor in
                    if success {
                        self.dismiss()
                    }
                }
            }
        }
    }
    
    public func dismiss() {
        self.isLocked = false
        window?.orderOut(nil)
        window = nil
        onUnlocked?()
    }
}

public struct PrivacyCurtainView: View {
    @ObservedObject private var curtain = PrivacyCurtainController.shared
    
    public var body: some View {
        ZStack {
            VisualEffectBackgroundView(material: .fullScreenUI, blendingMode: .withinWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: 6) {
                    Text("APEX Biometric Shield")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(curtain.currentProtectedAppName) is protected by FaceLock.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Button(action: { curtain.unlock() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "touchid")
                            .font(.system(size: 16))
                        Text("Unlock with Touch ID")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.cyan.opacity(0.8))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                    )
            )
        }
    }
}

public struct VisualEffectBackgroundView: NSViewRepresentable {
    public let material: NSVisualEffectView.Material
    public let blendingMode: NSVisualEffectView.BlendingMode

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
