import Foundation
import AppKit

public final class DeepResidualFinder: Sendable {
    public static let shared = DeepResidualFinder()
    
    private init() {}
    
    public func findResidue(for app: InstalledApp) -> [AppResidualItem] {
        var items: [AppResidualItem] = []
        
        items.append(AppResidualItem(url: app.bundleURL, category: .application, isSelected: true))
        
        let home = FileManager.default.homeDirectoryForCurrentUser
        let library = home.appendingPathComponent("Library")
        
        let appName = app.name.lowercased()
        let bundleId = app.bundleIdentifier.lowercased()
        
        let searchLocations: [(url: URL, category: ResidualCategory)] = [
            (library.appendingPathComponent("Application Support"), .appSupport),
            (library.appendingPathComponent("Caches"), .caches),
            (library.appendingPathComponent("Preferences"), .preferences),
            (library.appendingPathComponent("Saved Application State"), .savedState),
            (library.appendingPathComponent("Containers"), .containers),
            (library.appendingPathComponent("Group Containers"), .containers),
            (library.appendingPathComponent("Logs"), .logs),
            (library.appendingPathComponent("HTTPStorages"), .caches),
            (library.appendingPathComponent("WebKit"), .caches),
            (library.appendingPathComponent("LaunchAgents"), .launchAgents)
        ]
        
        let fm = FileManager.default
        
        for (dirURL, category) in searchLocations {
            guard let contents = try? fm.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
                continue
            }
            
            for itemURL in contents {
                let itemName = itemURL.lastPathComponent.lowercased()
                
                let matchesBundleId = !bundleId.isEmpty && itemName.contains(bundleId)
                let matchesAppName = !appName.isEmpty && (
                    itemName == appName ||
                    itemName.starts(with: appName + ".") ||
                    itemName.starts(with: appName + "-") ||
                    itemName.starts(with: appName + "_") ||
                    itemName.starts(with: "com." + appName)
                )
                
                if matchesBundleId || matchesAppName {
                    items.append(AppResidualItem(url: itemURL, category: category, isSelected: true))
                }
            }
        }
        
        return items
    }
    
    public func trashItems(_ items: [AppResidualItem], completion: @escaping @Sendable (Int, Int64) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var trashedCount = 0
            var trashedBytes: Int64 = 0
            
            for item in items where item.isSelected {
                var resultingURL: NSURL?
                do {
                    try FileManager.default.trashItem(at: item.url, resultingItemURL: &resultingURL)
                    trashedCount += 1
                    trashedBytes += item.sizeBytes
                } catch {
                    // Item locked or missing
                }
            }
            
            completion(trashedCount, trashedBytes)
        }
    }
}
