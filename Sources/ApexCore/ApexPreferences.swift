import Foundation
import Combine

@MainActor
public final class ApexPreferences: ObservableObject {
    public static let shared = ApexPreferences()
    
    private let defaults = UserDefaults.standard
    private let prefix = "apex.preference."
    
    @Published public var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: prefix + "launchAtLogin") }
    }
    
    @Published public var notchBarEnabled: Bool {
        didSet { defaults.set(notchBarEnabled, forKey: prefix + "notchBarEnabled") }
    }
    
    @Published public var fileShelfFloating: Bool {
        didSet { defaults.set(fileShelfFloating, forKey: prefix + "fileShelfFloating") }
    }
    
    @Published public var faceLockEnabled: Bool {
        didSet { defaults.set(faceLockEnabled, forKey: prefix + "faceLockEnabled") }
    }
    
    @Published public var telegramAlertsEnabled: Bool {
        didSet { defaults.set(telegramAlertsEnabled, forKey: prefix + "telegramAlertsEnabled") }
    }
    
    @Published public var telegramBotToken: String {
        didSet { defaults.set(telegramBotToken, forKey: prefix + "telegramBotToken") }
    }
    
    @Published public var telegramChatId: String {
        didSet { defaults.set(telegramChatId, forKey: prefix + "telegramChatId") }
    }
    
    @Published public var protectedApps: [String] {
        didSet { defaults.set(protectedApps, forKey: prefix + "protectedApps") }
    }
    
    private init() {
        self.launchAtLogin = defaults.bool(forKey: prefix + "launchAtLogin")
        self.notchBarEnabled = defaults.object(forKey: prefix + "notchBarEnabled") as? Bool ?? true
        self.fileShelfFloating = defaults.bool(forKey: prefix + "fileShelfFloating")
        self.faceLockEnabled = defaults.bool(forKey: prefix + "faceLockEnabled")
        self.telegramAlertsEnabled = defaults.bool(forKey: prefix + "telegramAlertsEnabled")
        self.telegramBotToken = defaults.string(forKey: prefix + "telegramBotToken") ?? ""
        self.telegramChatId = defaults.string(forKey: prefix + "telegramChatId") ?? ""
        self.protectedApps = defaults.stringArray(forKey: prefix + "protectedApps") ?? [
            "com.apple.Notes",
            "ru.keepcoder.Telegram",
            "com.apple.Photos"
        ]
    }
    
    public func isModuleEnabled(named id: String) -> Bool {
        let key = prefix + "module." + id + ".enabled"
        if defaults.object(forKey: key) == nil {
            return true
        }
        return defaults.bool(forKey: key)
    }
    
    public func setModuleEnabled(named id: String, enabled: Bool) {
        let key = prefix + "module." + id + ".enabled"
        defaults.set(enabled, forKey: key)
    }
}
