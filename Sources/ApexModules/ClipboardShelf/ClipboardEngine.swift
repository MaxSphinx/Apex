import Foundation
import AppKit

public enum ClipboardItemType: String, Codable, Sendable {
    case text
    case image
    case fileURL
    case color
}

public struct ClipboardItem: Identifiable, Hashable, @unchecked Sendable {
    public let id: UUID
    public let type: ClipboardItemType
    public let textContent: String?
    public let image: NSImage?
    public let fileURLs: [URL]?
    public let timestamp: Date
    public var isPinned: Bool
    
    public init(
        id: UUID = UUID(),
        type: ClipboardItemType,
        textContent: String? = nil,
        image: NSImage? = nil,
        fileURLs: [URL]? = nil,
        timestamp: Date = Date(),
        isPinned: Bool = false
    ) {
        self.id = id
        self.type = type
        self.textContent = textContent
        self.image = image
        self.fileURLs = fileURLs
        self.timestamp = timestamp
        self.isPinned = isPinned
    }
    
    public var previewTitle: String {
        switch type {
        case .text:
            return textContent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Empty Text"
        case .image:
            return "Image (Bitmap)"
        case .fileURL:
            if let urls = fileURLs, let first = urls.first {
                return urls.count > 1 ? "\(first.lastPathComponent) (+\(urls.count - 1) files)" : first.lastPathComponent
            }
            return "File URL"
        case .color:
            return "Color Snippet"
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }
}

private struct StoredClipboardItem: Codable {
    let id: String
    let type: String
    let textContent: String?
    let fileURLs: [String]?
    let timestamp: Date
    let isPinned: Bool
}

@MainActor
public final class ClipboardEngine: ObservableObject {
    public static let shared = ClipboardEngine()
    
    @Published public private(set) var items: [ClipboardItem] = []
    
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    private let maxItemsCount = 50
    private let storageURL: URL
    
    private init() {
        self.lastChangeCount = NSPasteboard.general.changeCount
        let home = FileManager.default.homeDirectoryForCurrentUser
        let dir = home.appendingPathComponent(".apex")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.storageURL = dir.appendingPathComponent("clipboard_history.json")
        loadStoredItems()
    }
    
    public func start() {
        stop()
        self.lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPasteboard()
            }
        }
    }
    
    public func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    public func clearAll() {
        items.removeAll(where: { !$0.isPinned })
        saveToDisk()
    }
    
    public func removeItem(_ item: ClipboardItem) {
        items.removeAll(where: { $0.id == item.id })
        saveToDisk()
    }
    
    public func togglePin(_ item: ClipboardItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].isPinned.toggle()
            saveToDisk()
        }
    }
    
    public func copyToPasteboard(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        
        switch item.type {
        case .text:
            if let text = item.textContent {
                pb.setString(text, forType: .string)
            }
        case .image:
            if let img = item.image, let tiff = img.tiffRepresentation {
                pb.setData(tiff, forType: .tiff)
            }
        case .fileURL:
            if let urls = item.fileURLs {
                pb.writeObjects(urls as [NSURL])
            }
        case .color:
            break
        }
        
        self.lastChangeCount = pb.changeCount
    }

    public func pasteDirectly(_ item: ClipboardItem) {
        copyToPasteboard(item)
        ApexHUDWindowController.shared.hide()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            let src = CGEventSource(stateID: .hidSystemState)
            // Virtual key 9 is 'v'
            if let keyDown = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: true),
               let keyUp = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: false) {
                keyDown.flags = .maskCommand
                keyUp.flags = .maskCommand
                keyDown.post(tap: .cghidEventTap)
                keyUp.post(tap: .cghidEventTap)
            }
        }
    }
    
    private func checkPasteboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount
        
        let types = pb.types ?? []
        for type in types {
            let raw = type.rawValue
            if raw == "org.nspasteboard.ConcealedType" ||
               raw.contains("onepassword") ||
               raw.contains("bitwarden") ||
               raw.contains("TransientType") ||
               raw.contains("AutoGeneratedType") {
                return
            }
        }
        
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            let item = ClipboardItem(type: .fileURL, fileURLs: urls)
            prependItem(item)
            return
        }
        
        if let image = NSImage(pasteboard: pb) {
            let item = ClipboardItem(type: .image, image: image)
            prependItem(item)
            return
        }
        
        if let text = pb.string(forType: .string), !text.isEmpty {
            if let first = items.first, first.type == .text && first.textContent == text {
                return
            }
            let item = ClipboardItem(type: .text, textContent: text)
            prependItem(item)
            return
        }
    }
    
    private func prependItem(_ item: ClipboardItem) {
        self.items.insert(item, at: 0)
        if self.items.count > self.maxItemsCount {
            if let unpinnedIndex = self.items.lastIndex(where: { !$0.isPinned }) {
                self.items.remove(at: unpinnedIndex)
            }
        }
        saveToDisk()
    }
    
    private func saveToDisk() {
        let serializable = items.prefix(30).compactMap { item -> StoredClipboardItem? in
            let typeStr = item.type.rawValue
            let urlsStr = item.fileURLs?.map { $0.path }
            return StoredClipboardItem(
                id: item.id.uuidString,
                type: typeStr,
                textContent: item.textContent,
                fileURLs: urlsStr,
                timestamp: item.timestamp,
                isPinned: item.isPinned
            )
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(serializable) {
            try? data.write(to: storageURL)
        }
    }
    
    private func loadStoredItems() {
        guard let data = try? Data(contentsOf: storageURL),
              let list = try? JSONDecoder().decode([StoredClipboardItem].self, from: data) else {
            return
        }
        
        self.items = list.compactMap { s in
            let type = ClipboardItemType(rawValue: s.type) ?? .text
            let urls = s.fileURLs?.map { URL(fileURLWithPath: $0) }
            return ClipboardItem(
                id: UUID(uuidString: s.id) ?? UUID(),
                type: type,
                textContent: s.textContent,
                image: nil,
                fileURLs: urls,
                timestamp: s.timestamp,
                isPinned: s.isPinned
            )
        }
    }
}
