import Foundation
import AppKit
import Combine

@MainActor
public final class BiometricShieldModule: ApexModule {
    public let id: String = "biometric_shield"
    public let name: String = "Biometric Shield"
    public let description: String = "Neural Engine FaceLock privacy curtain and Telegram security alerts."
    public let iconName: String = "faceid"
    
    @Published public var isEnabled: Bool {
        didSet {
            ApexPreferences.shared.setModuleEnabled(named: id, enabled: isEnabled)
            if isEnabled {
                start()
            } else {
                stop()
            }
        }
    }
    
    private var workspaceObserver: Any?
    private var unlockedSessions: Set<String> = []
    
    public init() {
        self.isEnabled = ApexPreferences.shared.isModuleEnabled(named: "biometric_shield")
    }
    
    public func start() {
        guard isEnabled else { return }
        
        // Camera capture is strictly on-demand to preserve privacy and zero CPU/battery load.
        // It starts ONLY when a protected app is foregrounded and immediately stops after verification.
        
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            let bid = app?.bundleIdentifier
            let name = app?.localizedName
            MainActor.assumeIsolated {
                self?.handleAppActivated(bundleIdentifier: bid, appName: name)
            }
        }
    }
    
    public func stop() {
        if let obs = workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            self.workspaceObserver = nil
        }
        BiometricFaceEngine.shared.stopCapture()
        PrivacyCurtainController.shared.dismiss()
        unlockedSessions.removeAll()
    }
    
    private func handleAppActivated(bundleIdentifier: String?, appName: String?) {
        guard ApexPreferences.shared.faceLockEnabled else { return }
        guard let bid = bundleIdentifier else { return }
        
        let protectedList = ApexPreferences.shared.protectedApps
        guard protectedList.contains(bid) else { return }
        
        if unlockedSessions.contains(bid) {
            return
        }
        
        BiometricFaceEngine.shared.verifyOwner(timeout: 1.5) { [weak self] success, dist, photo in
            guard let self = self else { return }
            if success {
                self.unlockedSessions.insert(bid)
            } else {
                PrivacyCurtainController.shared.lock(appName: appName ?? "Protected App", photo: photo)
                PrivacyCurtainController.shared.onUnlocked = { [weak self] in
                    self?.unlockedSessions.insert(bid)
                }
            }
        }
    }
}
