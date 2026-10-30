import Foundation
import Combine

@MainActor
public final class ClipboardModule: ApexModule {
    public let id: String = "clipboard_history"
    public let name: String = "Clipboard History"
    public let description: String = "In-memory secure clipboard history with password manager concealment."
    public let iconName: String = "doc.on.clipboard.fill"
    
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
        self.isEnabled = ApexPreferences.shared.isModuleEnabled(named: "clipboard_history")
    }
    
    public func start() {
        guard isEnabled else { return }
        ClipboardEngine.shared.start()
    }
    
    public func stop() {
        ClipboardEngine.shared.stop()
    }
}

@MainActor
public final class FileShelfModule: ApexModule {
    public let id: String = "file_shelf"
    public let name: String = "File Drop Shelf"
    public let description: String = "Floating parking shelf for staging files across multi-space workflows."
    public let iconName: String = "tray.and.arrow.down.fill"
    
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
        self.isEnabled = ApexPreferences.shared.isModuleEnabled(named: "file_shelf")
    }
    
    public func start() {
        guard isEnabled else { return }
        HotkeyManager.shared.onToggleShelfRequested = {
            ShelfWindowController.shared.toggle()
        }
        if ApexPreferences.shared.fileShelfFloating {
            ShelfWindowController.shared.show()
        }
    }
    
    public func stop() {
        HotkeyManager.shared.onToggleShelfRequested = nil
        ShelfWindowController.shared.hide()
    }
}
