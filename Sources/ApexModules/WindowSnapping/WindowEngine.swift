import Foundation
import AppKit
import ApplicationServices

@MainActor
public final class WindowEngine {
    public static let shared = WindowEngine()
    
    private init() {}
    
    @discardableResult
    public func snapFocusedWindow(to action: WindowSnapAction) -> Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return false }
        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)
        
        var focusedWindowValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindowValue)
        guard result == .success, let windowElement = focusedWindowValue as! AXUIElement? else {
            return false
        }
        
        guard let screen = getTargetScreen(for: windowElement) else { return false }
        let targetRect = calculateTargetRect(for: action, on: screen)
        
        return apply(frame: targetRect, to: windowElement, screen: screen)
    }
    
    private func getTargetScreen(for windowElement: AXUIElement) -> NSScreen? {
        var posValue: AnyObject?
        var sizeValue: AnyObject?
        
        AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &posValue)
        AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &sizeValue)
        
        var windowPoint = CGPoint.zero
        var windowSize = CGSize.zero
        
        if let posVal = posValue, CFGetTypeID(posVal) == AXValueGetTypeID() {
            AXValueGetValue(posVal as! AXValue, .cgPoint, &windowPoint)
        }
        if let sizeVal = sizeValue, CFGetTypeID(sizeVal) == AXValueGetTypeID() {
            AXValueGetValue(sizeVal as! AXValue, .cgSize, &windowSize)
        }
        
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080
        let windowMidPoint = CGPoint(
            x: windowPoint.x + windowSize.width / 2.0,
            y: primaryHeight - (windowPoint.y + windowSize.height / 2.0)
        )
        
        for screen in NSScreen.screens {
            if screen.frame.contains(windowMidPoint) {
                return screen
            }
        }
        
        let mouseLoc = NSEvent.mouseLocation
        for screen in NSScreen.screens {
            if screen.frame.contains(mouseLoc) {
                return screen
            }
        }
        
        return NSScreen.main ?? NSScreen.screens.first
    }
    
    public func calculateTargetRect(for action: WindowSnapAction, on screen: NSScreen) -> CGRect {
        let vf = screen.visibleFrame
        
        switch action {
        case .leftHalf:
            return CGRect(x: vf.minX, y: vf.minY, width: vf.width / 2.0, height: vf.height)
        case .rightHalf:
            return CGRect(x: vf.minX + vf.width / 2.0, y: vf.minY, width: vf.width / 2.0, height: vf.height)
        case .topHalf:
            return CGRect(x: vf.minX, y: vf.minY + vf.height / 2.0, width: vf.width, height: vf.height / 2.0)
        case .bottomHalf:
            return CGRect(x: vf.minX, y: vf.minY, width: vf.width, height: vf.height / 2.0)
        case .topLeftQuarter:
            return CGRect(x: vf.minX, y: vf.minY + vf.height / 2.0, width: vf.width / 2.0, height: vf.height / 2.0)
        case .topRightQuarter:
            return CGRect(x: vf.minX + vf.width / 2.0, y: vf.minY + vf.height / 2.0, width: vf.width / 2.0, height: vf.height / 2.0)
        case .bottomLeftQuarter:
            return CGRect(x: vf.minX, y: vf.minY, width: vf.width / 2.0, height: vf.height / 2.0)
        case .bottomRightQuarter:
            return CGRect(x: vf.minX + vf.width / 2.0, y: vf.minY, width: vf.width / 2.0, height: vf.height / 2.0)
        case .leftThird:
            return CGRect(x: vf.minX, y: vf.minY, width: vf.width / 3.0, height: vf.height)
        case .centerThird:
            return CGRect(x: vf.minX + vf.width / 3.0, y: vf.minY, width: vf.width / 3.0, height: vf.height)
        case .rightThird:
            return CGRect(x: vf.minX + (vf.width * 2.0 / 3.0), y: vf.minY, width: vf.width / 3.0, height: vf.height)
        case .leftTwoThirds:
            return CGRect(x: vf.minX, y: vf.minY, width: vf.width * 2.0 / 3.0, height: vf.height)
        case .rightTwoThirds:
            return CGRect(x: vf.minX + vf.width / 3.0, y: vf.minY, width: vf.width * 2.0 / 3.0, height: vf.height)
        case .maximize:
            return vf
        case .center:
            let width = min(vf.width * 0.75, 1200)
            let height = min(vf.height * 0.75, 800)
            return CGRect(
                x: vf.minX + (vf.width - width) / 2.0,
                y: vf.minY + (vf.height - height) / 2.0,
                width: width,
                height: height
            )
        }
    }
    
    private func apply(frame: CGRect, to windowElement: AXUIElement, screen: NSScreen) -> Bool {
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080
        
        var axPoint = CGPoint(
            x: frame.origin.x,
            y: primaryHeight - (frame.origin.y + frame.height)
        )
        var axSize = CGSize(
            width: frame.width,
            height: frame.height
        )
        
        guard let posVal = AXValueCreate(.cgPoint, &axPoint),
              let sizeVal = AXValueCreate(.cgSize, &axSize) else {
            return false
        }
        
        AXUIElementSetAttributeValue(windowElement, kAXPositionAttribute as CFString, posVal)
        AXUIElementSetAttributeValue(windowElement, kAXSizeAttribute as CFString, sizeVal)
        AXUIElementSetAttributeValue(windowElement, kAXPositionAttribute as CFString, posVal)
        
        return true
    }
}
