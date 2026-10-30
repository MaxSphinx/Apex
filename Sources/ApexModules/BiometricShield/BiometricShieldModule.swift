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
        
        FaceDetectionEngine.shared.startCapture()
        
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
        FaceDetectionEngine.shared.stopCapture()
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
        
        if !FaceDetectionEngine.shared.isFacePresent {
            PrivacyCurtainController.shared.lock(appName: appName ?? "Protected App")
            PrivacyCurtainController.shared.onUnlocked = { [weak self] in
                self?.unlockedSessions.insert(bid)
            }
        } else {
            unlockedSessions.insert(bid)
        }
    }
}
