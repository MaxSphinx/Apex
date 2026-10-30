import Foundation
import AppKit

public enum ResidualCategory: String, CaseIterable, Identifiable, Sendable {
    case application = "Application Bundle"
    case appSupport = "Application Support"
    case caches = "Caches & Temporary"
    case preferences = "Preferences & Settings"
    case savedState = "Saved Application State"
    case containers = "Sandbox & Containers"
    case logs = "Crash & System Logs"
    case launchAgents = "Launch Agents & Daemons"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .application: return "app.badge"
        case .appSupport: return "folder.fill"
        case .caches: return "bolt.horizontal.fill"
        case .preferences: return "gearshape.fill"
        case .savedState: return "clock.arrow.circlepath"
        case .containers: return "shippingbox.fill"
        case .logs: return "doc.text.fill"
        case .launchAgents: return "antenna.radiowaves.left.and.right"
        }
    }
}

public struct AppResidualItem: Identifiable, Hashable, @unchecked Sendable {
    public let id: String
    public let url: URL
    public let path: String
    public let name: String
    public let sizeBytes: Int64
    public let category: ResidualCategory
    public var isSelected: Bool
    
    public init(url: URL, category: ResidualCategory, isSelected: Bool = true) {
        self.id = url.path
        self.url = url
        self.path = url.path
        self.name = url.lastPathComponent
        self.category = category
        self.isSelected = isSelected
        self.sizeBytes = AppResidualItem.calculateSize(of: url)
    }
    
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
    
    private static func calculateSize(of url: URL) -> Int64 {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }
        
        if !isDir.boolValue {
            let attr = try? FileManager.default.attributesOfItem(atPath: url.path)
            return (attr?[.size] as? Int64) ?? 0
        }
        
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey],
            options: [],
            errorHandler: nil
        ) else { return 0 }
        
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            let values = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey])
            total += Int64(values?.totalFileAllocatedSize ?? values?.fileAllocatedSize ?? 0)
        }
        return total
    }
}

public struct InstalledApp: Identifiable, Hashable, @unchecked Sendable {
    public var id: String { bundleURL.path }
    public let name: String
    public let bundleIdentifier: String
    public let version: String
    public let bundleURL: URL
    public let icon: NSImage?
    public let sizeBytes: Int64
    
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
}
