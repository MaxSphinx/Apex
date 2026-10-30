import Foundation
import AppKit

@MainActor
public final class TelegramAlertEngine {
    public static let shared = TelegramAlertEngine()

    private let session = URLSession(configuration: .default)

    private init() {}

    public func sendIntruderAlert(appName: String, photo: NSImage? = nil, completion: (@MainActor (Bool) -> Void)? = nil) {
        let prefs = ApexPreferences.shared
        guard prefs.telegramAlertsEnabled else {
            completion?(false)
            return
        }

        var token = prefs.telegramBotToken.trimmingCharacters(in: .whitespacesAndNewlines)
        var chatId = prefs.telegramChatId.trimmingCharacters(in: .whitespacesAndNewlines)

        // Fallback to existing bot credentials if not explicitly populated
        if token.isEmpty || chatId.isEmpty {
            token = "8998738835:AAFonQCj9OiFxux7gNnk6KQWoXp7jLElPQg"
            chatId = "8934852439"
        }

        guard !token.isEmpty, !chatId.isEmpty else {
            completion?(false)
            return
        }

        let hostName = Host.current().localizedName ?? "MacBook"
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss (dd.MM.yyyy)"
        let timeStr = formatter.string(from: Date())

        let caption = """
        🚨 <b>APEX Biometric Shield Alert</b>
        💻 <b>Устройство:</b> \(escapeHTML(hostName))
        🎯 <b>Цель:</b> \(escapeHTML(appName))
        🕒 <b>Время:</b> \(timeStr)
        🔒 <i>Экран заблокирован приватной шторкой APEX.</i>
        """

        if let intruderPhoto = photo,
           let tiff = intruderPhoto.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let jpegData = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.85]) {
            sendPhoto(token: token, chatId: chatId, photoData: jpegData, caption: caption, completion: completion)
        } else {
            sendMessage(token: token, chatId: chatId, text: caption, completion: completion)
        }
    }

    private func sendPhoto(token: String, chatId: String, photoData: Data, caption: String, completion: (@MainActor (Bool) -> Void)?) {
        guard let url = URL(string: "https://api.telegram.org/bot\(token)/sendPhoto") else {
            completion?(false)
            return
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"chat_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(chatId)\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"parse_mode\"\r\n\r\n".data(using: .utf8)!)
        body.append("HTML\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"caption\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(caption)\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"intruder.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(photoData)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        session.dataTask(with: request) { _, response, error in
            let success = (error == nil && (response as? HTTPURLResponse)?.statusCode == 200)
            Task { @MainActor in
                completion?(success)
            }
        }.resume()
    }

    private func sendMessage(token: String, chatId: String, text: String, completion: (@MainActor (Bool) -> Void)?) {
        guard let url = URL(string: "https://api.telegram.org/bot\(token)/sendMessage") else {
            completion?(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "chat_id": chatId,
            "text": text,
            "parse_mode": "HTML"
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])

        session.dataTask(with: request) { _, response, error in
            let success = (error == nil && (response as? HTTPURLResponse)?.statusCode == 200)
            Task { @MainActor in
                completion?(success)
            }
        }.resume()
    }

    private func escapeHTML(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
