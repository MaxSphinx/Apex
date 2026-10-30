import Foundation

@MainActor
public final class TelegramAlertEngine {
    public static let shared = TelegramAlertEngine()
    
    private init() {}
    
    public func sendIntruderAlert(appName: String, completion: (@MainActor (Bool) -> Void)? = nil) {
        let prefs = ApexPreferences.shared
        guard prefs.telegramAlertsEnabled else { return }
        
        let token = prefs.telegramBotToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let chatId = prefs.telegramChatId.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !token.isEmpty, !chatId.isEmpty else {
            completion?(false)
            return
        }
        
        let hostName = Host.current().localizedName ?? "MacBook"
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        let messageText = """
        🚨 *APEX Biometric Shield Alert*
        
        *Device:* \(hostName)
        *Protected Target:* \(appName)
        *Timestamp:* \(timestamp)
        *Reason:* Unauthorized access or biometric face check failed.
        """
        
        guard let url = URL(string: "https://api.telegram.org/bot\(token)/sendMessage") else {
            completion?(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "chat_id": chatId,
            "text": messageText,
            "parse_mode": "Markdown"
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let success = (error == nil && (response as? HTTPURLResponse)?.statusCode == 200)
            Task { @MainActor in
                completion?(success)
            }
        }.resume()
    }
}
