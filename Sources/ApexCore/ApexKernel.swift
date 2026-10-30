import Foundation
import AppKit
import Combine

@MainActor
public final class ApexKernel: ObservableObject {
    public static let shared = ApexKernel()
    
    private var statusItem: NSStatusItem?
    private var modules: [String: any ApexModule] = [:]
    
    public let windowSnapping = WindowSnappingModule()
    public let volumeMixer = VolumeMixerModule()
    public let systemStats = SystemStatsModule()
    public let appCleaner = AppCleanerModule()
    public let clipboard = ClipboardModule()
    public let fileShelf = FileShelfModule()
    public let biometricShield = BiometricShieldModule()
    public let peripheralInput = PeripheralInputModule()
    public let displayPower = DisplayPowerModule()
    public let quickTools = QuickToolsModule()
    
    private init() {
        registerModules()
    }
    
    private func registerModules() {
        modules[windowSnapping.id] = windowSnapping
        modules[volumeMixer.id] = volumeMixer
        modules[systemStats.id] = systemStats
        modules[appCleaner.id] = appCleaner
        modules[clipboard.id] = clipboard
        modules[fileShelf.id] = fileShelf
        modules[biometricShield.id] = biometricShield
        modules[peripheralInput.id] = peripheralInput
        modules[displayPower.id] = displayPower
        modules[quickTools.id] = quickTools
    }
    
    public func boot() {
        setupStatusItem()
        setupHotkeys()
        startEnabledModules()
        PermissionsManager.shared.checkAll()
    }
    
    private func startEnabledModules() {
        for (_, module) in modules {
            if module.isEnabled {
                module.start()
            }
        }
    }
    
    private func setupHotkeys() {
        HotkeyManager.shared.start()
        HotkeyManager.shared.onToggleHUDRequested = { [weak self] in
            Task { @MainActor in
                self?.toggleHUD()
            }
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else { return }
        
        // Draw crisp peak icon ▲
        let icon = createPeakIcon()
        button.image = icon
        button.imagePosition = .imageOnly
        button.toolTip = "APEX Toolkit (Click to open, Right-Click for menu)"
        button.target = self
        button.action = #selector(statusItemClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    
    private func createPeakIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let path = NSBezierPath()
            // Sleek triangle peak
            path.move(to: NSPoint(x: 9, y: 14))
            path.line(to: NSPoint(x: 15, y: 4))
            path.line(to: NSPoint(x: 3, y: 4))
            path.close()
            
            path.lineJoinStyle = .round
            path.lineWidth = 1.6
            
            NSColor.labelColor.setStroke()
            path.stroke()
            
            // Subtle center glow dot
            let dot = NSBezierPath(ovalIn: NSRect(x: 7.75, y: 6.5, width: 2.5, height: 2.5))
            NSColor.labelColor.setFill()
            dot.fill()
            
            return true
        }
        image.isTemplate = true
        return image
    }
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let currentEvent = NSApp.currentEvent
        if currentEvent?.type == .rightMouseUp || currentEvent?.modifierFlags.contains(.control) == true {
            showContextMenu()
        } else {
            toggleHUD()
        }
    }
    
    public func toggleHUD() {
        ApexHUDWindowController.shared.toggle(relativeTo: statusItem?.button)
    }
    
    private func showContextMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "APEX Toolkit v1.0.0", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        let openHUDItem = NSMenuItem(title: "Open Liquid HUD", action: #selector(menuOpenHUD), keyEquivalent: "a")
        openHUDItem.keyEquivalentModifierMask = [.command, .option]
        openHUDItem.target = self
        menu.addItem(openHUDItem)
        
        let shelfItem = NSMenuItem(title: "Toggle File Shelf", action: #selector(menuToggleShelf), keyEquivalent: "s")
        shelfItem.keyEquivalentModifierMask = [.command, .option]
        shelfItem.target = self
        menu.addItem(shelfItem)
        
        let notchItem = NSMenuItem(title: "Toggle Notch Bar", action: #selector(menuToggleNotch), keyEquivalent: "")
        notchItem.target = self
        menu.addItem(notchItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let purgeItem = NSMenuItem(title: "Purge Inactive Memory", action: #selector(menuPurgeMemory), keyEquivalent: "")
        purgeItem.target = self
        menu.addItem(purgeItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let repoItem = NSMenuItem(title: "GitHub Repository...", action: #selector(menuOpenGitHub), keyEquivalent: "")
        repoItem.target = self
        menu.addItem(repoItem)
        
        menu.addItem(NSMenuItem(title: "Quit APEX", action: #selector(menuQuit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc private func menuOpenHUD() {
        toggleHUD()
    }
    
    @objc private func menuToggleShelf() {
        ShelfWindowController.shared.toggle()
    }
    
    @objc private func menuToggleNotch() {
        NotchBarController.shared.toggle()
    }
    
    @objc private func menuPurgeMemory() {
        MemoryStatsEngine.shared.purgeMemory()
    }
    
    @objc private func menuOpenGitHub() {
        if let url = URL(string: "https://github.com/MaxSphinx/Apex") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func menuQuit() {
        NSApplication.shared.terminate(nil)
    }
}
