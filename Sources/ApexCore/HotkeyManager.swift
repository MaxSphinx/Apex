import Foundation
import AppKit

@MainActor
public final class HotkeyManager {
    public static let shared = HotkeyManager()
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    public var onSnapRequested: ((WindowSnapAction) -> Void)?
    public var onToggleHUDRequested: (() -> Void)?
    public var onToggleShelfRequested: (() -> Void)?
    
    private init() {}
    
    public func start() {
        stop()
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in
                self?.handleKeyEvent(event)
            }
        }
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil
            }
            return event
        }
    }
    
    public func stop() {
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }
    
    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = event.keyCode
        
        // Control + Option (Window Snapping)
        if flags == [.control, .option] {
            switch keyCode {
            case 123: // Left Arrow
                onSnapRequested?(.leftHalf)
                return true
            case 124: // Right Arrow
                onSnapRequested?(.rightHalf)
                return true
            case 126: // Up Arrow
                onSnapRequested?(.maximize)
                return true
            case 125: // Down Arrow
                onSnapRequested?(.bottomHalf)
                return true
            case 36:  // Return / Enter
                onSnapRequested?(.maximize)
                return true
            case 8:   // C key (Center)
                onSnapRequested?(.center)
                return true
            case 32:  // U key (Top-Left)
                onSnapRequested?(.topLeftQuarter)
                return true
            case 34:  // I key (Top-Right)
                onSnapRequested?(.topRightQuarter)
                return true
            case 38:  // J key (Bottom-Left)
                onSnapRequested?(.bottomLeftQuarter)
                return true
            case 40:  // K key (Bottom-Right)
                onSnapRequested?(.bottomRightQuarter)
                return true
            case 2:   // D key (Left Third)
                onSnapRequested?(.leftThird)
                return true
            case 3:   // F key (Center Third)
                onSnapRequested?(.centerThird)
                return true
            case 5:   // G key (Right Third)
                onSnapRequested?(.rightThird)
                return true
            default:
                break
            }
        }
        
        // Command + Option + A (Toggle HUD)
        if flags == [.command, .option] && keyCode == 0 { // 0 is 'A'
            onToggleHUDRequested?()
            return true
        }
        
        // Command + Option + S (Toggle Drop Shelf)
        if flags == [.command, .option] && keyCode == 1 { // 1 is 'S'
            onToggleShelfRequested?()
            return true
        }
        
        return false
    }
}
