import Foundation
import Combine

@MainActor
public final class WindowSnappingModule: ApexModule {
    public let id: String = "window_snapping"
    public let name: String = "Window Snapping"
    public let description: String = "Zero-latency window grid snapping with shortcuts and drag hints."
    public let iconName: String = "rectangle.split.2x2"
    
    @Published public var isEnabled: Bool {
        didSet {
            ApexPreferences.shared.setModuleEnabled(named: id, enabled: isEnabled)
            if isEnabled {
                start()
            } else {
                stop()
            }
        }
    }
    
    public init() {
        self.isEnabled = ApexPreferences.shared.isModuleEnabled(named: "window_snapping")
    }
    
    public func start() {
        guard isEnabled else { return }
        HotkeyManager.shared.onSnapRequested = { [weak self] action in
            self?.handleSnap(action)
        }
        MouseEdgeSnappingDetector.shared.start()
        MouseEdgeSnappingDetector.shared.onSnapCommitted = { [weak self] action in
            self?.handleSnap(action)
        }
    }
    
    public func stop() {
        HotkeyManager.shared.onSnapRequested = nil
        MouseEdgeSnappingDetector.shared.stop()
        SnapPreviewWindow.shared.hide()
    }
    
    public func handleSnap(_ action: WindowSnapAction) {
        guard isEnabled else { return }
        WindowEngine.shared.snapFocusedWindow(to: action)
    }
}
