import Foundation
import AppKit
import SwiftUI

@MainActor
public final class ApexHUDWindowController: ObservableObject {
    public static let shared = ApexHUDWindowController()
    
    private var panel: NSPanel?
    private var localEventMonitor: Any?
    @Published public private(set) var isVisible: Bool = false
    
    private init() {}
    
    public func toggle(relativeTo statusItemButton: NSStatusBarButton? = nil) {
        if isVisible {
            hide()
        } else {
            show(relativeTo: statusItemButton)
        }
    }
    
    public func show(relativeTo statusItemButton: NSStatusBarButton? = nil) {
        if panel == nil {
            let p = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 470, height: 610),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            p.isOpaque = false
            p.backgroundColor = .clear
            p.level = .floating
            p.hasShadow = true
            p.appearance = NSAppearance(named: .darkAqua)
            p.isMovableByWindowBackground = false
            p.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            
            let hosting = NSHostingView(rootView: ApexHUDView())
            p.contentView = hosting
            self.panel = p
        }
        
        guard let p = panel, let screen = NSScreen.main else { return }
        
        var origin = CGPoint.zero
        let panelSize = CGSize(width: 470, height: 610)
        
        if let btn = statusItemButton, let window = btn.window {
            let buttonRectOnScreen = window.convertToScreen(btn.bounds)
            origin.x = min(
                max(screen.visibleFrame.minX + 10, buttonRectOnScreen.midX - panelSize.width / 2.0),
                screen.visibleFrame.maxX - panelSize.width - 10
            )
            origin.y = buttonRectOnScreen.minY - panelSize.height - 6
        } else {
            origin.x = screen.visibleFrame.maxX - panelSize.width - 20
            origin.y = screen.visibleFrame.maxY - panelSize.height - 10
        }
        
        p.setFrame(NSRect(origin: origin, size: panelSize), display: true)
        p.alphaValue = 0
        p.orderFrontRegardless()
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            p.animator().alphaValue = 1.0
        }
        
        isVisible = true
        startEventMonitoring()
    }
    
    public func hide() {
        guard isVisible, let p = panel else { return }
        stopEventMonitoring()
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.12
            p.animator().alphaValue = 0
        }, completionHandler: {
            MainActor.assumeIsolated {
                p.orderOut(nil)
                self.isVisible = false
            }
        })
    }
    
    private func startEventMonitoring() {
        stopEventMonitoring()
        localEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            Task { @MainActor in
                guard let self = self, let p = self.panel else { return }
                let clickLoc = NSEvent.mouseLocation
                if !p.frame.contains(clickLoc) {
                    self.hide()
                }
            }
        }
    }
    
    private func stopEventMonitoring() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            self.localEventMonitor = nil
        }
    }
}
