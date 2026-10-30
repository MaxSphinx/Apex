import Foundation
import AppKit
import AVFoundation
import UserNotifications

@MainActor
public final class PermissionsManager: ObservableObject {
    public static let shared = PermissionsManager()
    
    @Published public private(set) var isAccessibilityGranted: Bool = false
    @Published public private(set) var isCameraGranted: Bool = false
    @Published public private(set) var isNotificationGranted: Bool = false
    
    private init() {
        checkAll()
    }
    
    public func checkAll() {
        checkAccessibility()
        checkCamera()
        checkNotifications()
    }
    
    public func checkAccessibility() {
        let trusted = AXIsProcessTrusted()
        self.isAccessibilityGranted = trusted
    }
    
    public func requestAccessibility() {
        let promptKey = "AXTrustedCheckOptionPrompt" as CFString
        let options = [promptKey: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        self.isAccessibilityGranted = trusted
    }
    
    public func checkCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        self.isCameraGranted = (status == .authorized)
    }
    
    public func requestCamera(completion: @escaping @MainActor (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            let isGranted = granted
            Task { @MainActor in
                self.isCameraGranted = isGranted
                completion(isGranted)
            }
        }
    }
    
    public func checkNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let isGranted = (settings.authorizationStatus == .authorized)
            Task { @MainActor in
                self.isNotificationGranted = isGranted
            }
        }
    }
    
    public func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            let isGranted = granted
            Task { @MainActor in
                self.isNotificationGranted = isGranted
            }
        }
    }
    
    public func openAccessibilityPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
