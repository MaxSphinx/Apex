import AppKit

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run strictly as menu bar accessory without Dock clutter
        NSApp.setActivationPolicy(.accessory)
        
        // Boot the APEX microkernel
        ApexKernel.shared.boot()
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.stop()
        NotchBarController.shared.hide()
        ShelfWindowController.shared.hide()
    }
}
