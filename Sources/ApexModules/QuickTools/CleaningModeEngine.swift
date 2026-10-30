import Foundation
import AppKit
import CoreGraphics
import SwiftUI

@MainActor
public final class CleaningModeEngine: ObservableObject {
    public static let shared = CleaningModeEngine()
    
    @Published public private(set) var isActive: Bool = false
    @Published public private(set) var escapeCount: Int = 0
    public let unlockTarget: Int = 5
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var overlayWindow: NSPanel?
    
    private init() {}
    
    public func start() {
        guard !isActive else { return }
        
        escapeCount = 0
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) |
                                     (1 << CGEventType.keyUp.rawValue) |
                                     (1 << CGEventType.flagsChanged.rawValue)
        
        let callback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
            guard let ref = refcon else { return Unmanaged.passUnretained(event) }
            let engine = Unmanaged<CleaningModeEngine>.fromOpaque(ref).takeUnretainedValue()
            
            if type == .keyDown {
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                if keyCode == 53 { // ESC key
                    Task { @MainActor in
                        engine.handleEscapePress()
                    }
                }
            }
            // Swallow all keyboard events
            return nil
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
        self.isActive = true
        
        showOverlay()
    }
    
    public func stop() {
        guard isActive else { return }
        
        if let tap = eventTap, let source = runLoopSource {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            self.eventTap = nil
            self.runLoopSource = nil
        }
        
        hideOverlay()
        self.isActive = false
        self.escapeCount = 0
    }
    
    private func handleEscapePress() {
        escapeCount += 1
        if escapeCount >= unlockTarget {
            stop()
        }
    }
    
    private func showOverlay() {
        guard let screen = NSScreen.main else { return }
        
        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = NSColor.black.withAlphaComponent(0.65)
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        let view = NSHostingView(rootView: CleaningModeOverlayView())
        panel.contentView = view
        panel.orderFrontRegardless()
        
        self.overlayWindow = panel
    }
    
    private func hideOverlay() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
    }
}

public struct CleaningModeOverlayView: View {
    @ObservedObject private var engine = CleaningModeEngine.shared
    
    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 64, weight: .thin))
                .foregroundColor(.cyan)
            
            Text("Cleaning Mode Active")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Keyboard input is locked so you can wipe your keyboard and trackpad safely.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            
            VStack(spacing: 8) {
                Text("Press ESC 5 times to exit (\(engine.escapeCount)/\(engine.unlockTarget))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.yellow)
                
                ProgressView(value: Double(engine.escapeCount), total: Double(engine.unlockTarget))
                    .progressViewStyle(.linear)
                    .frame(width: 200)
                    .tint(.yellow)
            }
            .padding(.top, 10)
            
            Button(action: {
                CleaningModeEngine.shared.stop()
            }) {
                Text("Unlock Now")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.cyan))
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
