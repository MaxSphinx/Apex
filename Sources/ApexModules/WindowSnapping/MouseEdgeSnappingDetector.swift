import Foundation
import AppKit

@MainActor
public final class MouseEdgeSnappingDetector {
    public static let shared = MouseEdgeSnappingDetector()

    private var dragMonitor: Any?
    private var mouseUpMonitor: Any?
    private var pendingAction: WindowSnapAction?
    private var isTracking = false

    public var onSnapCommitted: ((WindowSnapAction) -> Void)?

    private init() {}

    public func start() {
        guard !isTracking else { return }
        isTracking = true

        dragMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
            MainActor.assumeIsolated {
                self?.handleMouseDragged(event)
            }
        }

        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            MainActor.assumeIsolated {
                self?.handleMouseUp(event)
            }
        }
    }

    public func stop() {
        if let dm = dragMonitor {
            NSEvent.removeMonitor(dm)
            dragMonitor = nil
        }
        if let um = mouseUpMonitor {
            NSEvent.removeMonitor(um)
            mouseUpMonitor = nil
        }
        SnapPreviewWindow.shared.hide()
        pendingAction = nil
        isTracking = false
    }

    private func handleMouseDragged(_ event: NSEvent) {
        let mouseLoc = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLoc) }) ?? NSScreen.main else {
            return
        }

        let f = screen.frame
        let edgeMargin: CGFloat = 8.0
        let cornerZoneRatio: CGFloat = 0.18

        var action: WindowSnapAction?

        if mouseLoc.y >= f.maxY - edgeMargin {
            // Top edge
            if mouseLoc.x <= f.minX + f.width * cornerZoneRatio {
                action = .topLeftQuarter
            } else if mouseLoc.x >= f.maxX - f.width * cornerZoneRatio {
                action = .topRightQuarter
            } else {
                action = .maximize
            }
        } else if mouseLoc.x <= f.minX + edgeMargin {
            // Left edge
            if mouseLoc.y >= f.maxY - f.height * cornerZoneRatio {
                action = .topLeftQuarter
            } else if mouseLoc.y <= f.minY + f.height * cornerZoneRatio {
                action = .bottomLeftQuarter
            } else {
                action = .leftHalf
            }
        } else if mouseLoc.x >= f.maxX - edgeMargin {
            // Right edge
            if mouseLoc.y >= f.maxY - f.height * cornerZoneRatio {
                action = .topRightQuarter
            } else if mouseLoc.y <= f.minY + f.height * cornerZoneRatio {
                action = .bottomRightQuarter
            } else {
                action = .rightHalf
            }
        } else if mouseLoc.y <= f.minY + edgeMargin {
            // Bottom edge
            action = .bottomHalf
        }

        if let act = action {
            if pendingAction != act {
                pendingAction = act
                let targetRect = WindowEngine.shared.calculateTargetRect(for: act, on: screen)
                SnapPreviewWindow.shared.show(at: targetRect)
            }
        } else {
            if pendingAction != nil {
                SnapPreviewWindow.shared.hide()
                pendingAction = nil
            }
        }
    }

    private func handleMouseUp(_ event: NSEvent) {
        guard let act = pendingAction else { return }
        SnapPreviewWindow.shared.hide()
        pendingAction = nil

        WindowEngine.shared.snapFocusedWindow(to: act)
        NSSound(named: "Tink")?.play()
        onSnapCommitted?(act)
    }
}
