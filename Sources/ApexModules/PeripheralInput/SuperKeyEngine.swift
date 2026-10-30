import Foundation
import AppKit
import CoreGraphics

public final class SuperKeyEngine: @unchecked Sendable {
    public static let shared = SuperKeyEngine()
    
    public private(set) var isEnabled: Bool = false
    private let lock = NSLock()
    
    private init() {}
    
    public func setEnabled(_ enable: Bool) {
        lock.lock()
        defer { lock.unlock() }
        
        if enable {
            applyCapsLockToHyperMapping()
            isEnabled = true
        } else {
            resetCapsLockMapping()
            isEnabled = false
        }
    }
    
    private func applyCapsLockToHyperMapping() {
        // Remap Caps Lock (0x700000039) to F18 (0x70000006D) via /usr/bin/hidutil
        let json = "{\"UserKeyMapping\":[{\"HIDKeyboardModifierMappingSrc\":0x700000039,\"HIDKeyboardModifierMappingDst\":0x70000006D}]}"
        runHidutil(arguments: ["property", "--set", json])
    }
    
    private func resetCapsLockMapping() {
        let json = "{\"UserKeyMapping\":[]}"
        runHidutil(arguments: ["property", "--set", json])
    }
    
    private func runHidutil(arguments: [String]) {
        let task = Process()
        task.launchPath = "/usr/bin/hidutil"
        task.arguments = arguments
        task.standardOutput = Pipe()
        task.standardError = Pipe()
        try? task.run()
        task.waitUntilExit()
    }
}
