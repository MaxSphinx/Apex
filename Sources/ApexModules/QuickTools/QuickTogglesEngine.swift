import Foundation
import AppKit

@MainActor
public final class QuickTogglesEngine: ObservableObject {
    public static let shared = QuickTogglesEngine()
    
    @Published public private(set) var showHiddenFiles: Bool = false
    @Published public private(set) var showDesktopIcons: Bool = true
    @Published public private(set) var isDarkMode: Bool = true
    
    private init() {
        refreshState()
    }
    
    public func refreshState() {
        let hidden = UserDefaults.standard.persistentDomain(forName: "com.apple.finder")?["AppleShowAllFiles"] as? Bool ?? false
        self.showHiddenFiles = hidden
        
        let desktop = UserDefaults.standard.persistentDomain(forName: "com.apple.finder")?["CreateDesktop"] as? Bool ?? true
        self.showDesktopIcons = desktop
        
        self.isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
    
    public func toggleHiddenFiles() {
        let newValue = !showHiddenFiles
        showHiddenFiles = newValue
        runShell("defaults write com.apple.finder AppleShowAllFiles -bool \(newValue) && killall Finder")
    }
    
    public func toggleDesktopIcons() {
        let newValue = !showDesktopIcons
        showDesktopIcons = newValue
        runShell("defaults write com.apple.finder CreateDesktop -bool \(newValue) && killall Finder")
    }
    
    public func toggleDarkMode() {
        let script = "tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode"
        runAppleScript(script)
        isDarkMode.toggle()
    }
    
    public func flushDNS() {
        runShell("dscacheutil -flushcache")
    }
    
    private func runShell(_ command: String) {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", command]
        try? task.run()
    }
    
    private func runAppleScript(_ script: String) {
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        try? task.run()
    }
}
