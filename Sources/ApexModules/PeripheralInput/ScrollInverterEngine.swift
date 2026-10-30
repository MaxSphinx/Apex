import Foundation
import CoreGraphics
import AppKit
import Combine

@MainActor
public final class ScrollInverterEngine: ObservableObject {
    public static let shared = ScrollInverterEngine()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    @Published public private(set) var isRunning: Bool = false
    @Published public var invertVertical: Bool = true
    @Published public var invertHorizontal: Bool = false
    
    private init() {}
    
    public func start() {
        guard !isRunning else { return }
        
        let eventMask: CGEventMask = (1 << CGEventType.scrollWheel.rawValue)
        
        let callback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
            guard type == .scrollWheel, let ref = refcon else {
                return Unmanaged.passUnretained(event)
            }
            let engine = Unmanaged<ScrollInverterEngine>.fromOpaque(ref).takeUnretainedValue()
            return engine.handleScrollWheel(event: event)
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
    
    public nonisolated func handleScrollWheel(event: CGEvent) -> Unmanaged<CGEvent>? {
        let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0
        let momentumPhase = event.getIntegerValueField(.scrollWheelEventMomentumPhase)
        let scrollPhase = event.getIntegerValueField(.scrollWheelEventScrollPhase)
        
        // Physical mouse wheels emit discrete events or continuous without gesture phases
        let isPhysicalWheel = !isContinuous || (momentumPhase == 0 && scrollPhase == 0)
        guard isPhysicalWheel else {
            return Unmanaged.passUnretained(event)
        }
        
        let deltaY = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
        let ptDeltaY = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
        let fixedPtY = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        
        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: -deltaY)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: -ptDeltaY)
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: -fixedPtY)
        
        return Unmanaged.passUnretained(event)
    }
}
