import Foundation
import CoreGraphics
import AppKit
import Combine

@MainActor
public final class MouseNavigationEngine: ObservableObject {
    public static let shared = MouseNavigationEngine()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    @Published public private(set) var isRunning: Bool = false
    @Published public var enableSideButtonsNavigation: Bool = true
    
    private init() {}
    
    public func start() {
        guard !isRunning else { return }
        
        let eventMask: CGEventMask = (1 << CGEventType.otherMouseDown.rawValue)
        
        let callback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
            guard type == .otherMouseDown, let ref = refcon else {
                return Unmanaged.passUnretained(event)
            }
            let engine = Unmanaged<MouseNavigationEngine>.fromOpaque(ref).takeUnretainedValue()
            return engine.handleOtherMouseDown(event: event)
        }
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return
        }
        
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        self.eventTap = tap
        self.runLoopSource = source
        self.isRunning = true
    }
    
    public func stop() {
        guard isRunning, let tap = eventTap, let source = runLoopSource else { return }
        
        CGEvent.tapEnable(tap: tap, enable: false)
        CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        self.eventTap = nil
        self.runLoopSource = nil
        self.isRunning = false
    }
    
    public nonisolated func handleOtherMouseDown(event: CGEvent) -> Unmanaged<CGEvent>? {
        let buttonNumber = event.getIntegerValueField(.mouseEventButtonNumber)
        
        // Button 3: Back (emit Cmd + [)
        if buttonNumber == 3 {
            postKeyboardShortcut(keyCode: 33, flags: .maskCommand) // [
            return nil
        }
        // Button 4: Forward (emit Cmd + ])
        else if buttonNumber == 4 {
            postKeyboardShortcut(keyCode: 30, flags: .maskCommand) // ]
            return nil
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    private nonisolated func postKeyboardShortcut(keyCode: CGKeyCode, flags: CGEventFlags) {
        let src = CGEventSource(stateID: .hidSystemState)
        if let down = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true) {
            down.flags = flags
            down.post(tap: .cghidEventTap)
        }
        if let up = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false) {
            up.flags = flags
            up.post(tap: .cghidEventTap)
        }
    }
}
