import Foundation
import AppKit

@MainActor
public final class SnapPreviewWindow: NSPanel {
    public static let shared = SnapPreviewWindow()
    
    private let visualEffectView = NSVisualEffectView()
    
    private init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.ignoresMouseEvents = true
        self.hasShadow = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        visualEffectView.material = .hudWindow
        visualEffectView.state = .active
        visualEffectView.blendingMode = .withinWindow
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 16
        visualEffectView.layer?.borderWidth = 1.5
        visualEffectView.layer?.borderColor = NSColor.systemTeal.withAlphaComponent(0.6).cgColor
        visualEffectView.layer?.backgroundColor = NSColor.systemTeal.withAlphaComponent(0.12).cgColor
        
        self.contentView = visualEffectView
    }
    
    public func show(at rect: CGRect) {
        setFrame(rect.insetBy(dx: 6, dy: 6), display: true)
        alphaValue = 0
        orderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            animator().alphaValue = 1.0
        }
    }
    
    public func hide() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            self.animator().alphaValue = 0
        }, completionHandler: {
            MainActor.assumeIsolated {
                self.orderOut(nil)
            }
        })
    }
}
