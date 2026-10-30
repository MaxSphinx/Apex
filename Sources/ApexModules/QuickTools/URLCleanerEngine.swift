import Foundation
import AppKit

@MainActor
public final class URLCleanerEngine: ObservableObject {
    public static let shared = URLCleanerEngine()
    
    @Published public private(set) var isRunning: Bool = false
    @Published public private(set) var cleanedCount: Int = 0
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    
    private let trackingParameters: Set<String> = [
        "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
        "fbclid", "gclid", "msclkid", "mc_eid", "si", "igshid", "yclid",
        "_hsenc", "_hsmi", "ref_src", "feature"
    ]
    
    private init() {}
    
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        lastChangeCount = NSPasteboard.general.changeCount
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPasteboard()
            }
        }
    }
    
    public func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    private func checkPasteboard() {
        let currentCount = NSPasteboard.general.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount
        
        guard let string = NSPasteboard.general.string(forType: .string) else { return }
        
        if let cleaned = cleanURLString(string), cleaned != string {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(cleaned, forType: .string)
            cleanedCount += 1
            lastChangeCount = NSPasteboard.general.changeCount
        }
    }
    
    public func cleanURLString(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://"),
              var components = URLComponents(string: trimmed) else {
            return nil
        }
        
        guard let queryItems = components.queryItems, !queryItems.isEmpty else {
            return nil
        }
        
        let filtered = queryItems.filter { !trackingParameters.contains($0.name.lowercased()) }
        components.queryItems = filtered.isEmpty ? nil : filtered
        
        return components.url?.absoluteString
    }
}
