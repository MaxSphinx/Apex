import Foundation
import AppKit

@MainActor
public final class AppScanner: ObservableObject {
    public static let shared = AppScanner()
    
    @Published public private(set) var installedApps: [InstalledApp] = []
    @Published public private(set) var isScanning: Bool = false
    
    private init() {
        scan()
    }
    
    public func scan() {
        guard !isScanning else { return }
        isScanning = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let appDirs = [
                URL(fileURLWithPath: "/Applications"),
                FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
            ]
            
            var found: [InstalledApp] = []
            let fm = FileManager.default
            
            for dir in appDirs {
                guard let contents = try? fm.contentsOfDirectory(
                    at: dir,
                    includingPropertiesForKeys: [.isApplicationKey, .fileSizeKey],
                    options: [.skipsHiddenFiles]
                ) else { continue }
                
                for url in contents where url.pathExtension == "app" {
                    guard let bundle = Bundle(url: url) else { continue }
                    
                    let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ??
                               (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String) ??
                               url.deletingPathExtension().lastPathComponent
                    let bundleId = bundle.bundleIdentifier ?? ""
                    let version = (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
                    let icon = NSWorkspace.shared.icon(forFile: url.path)
                    
                    let attr = try? fm.attributesOfItem(atPath: url.path)
                    let size = (attr?[.size] as? Int64) ?? 0
                    
                    let app = InstalledApp(
                        name: name,
                        bundleIdentifier: bundleId,
                        version: version,
                        bundleURL: url,
                        icon: icon,
                        sizeBytes: size
                    )
                    found.append(app)
                }
            }
            
            found.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            
            Task { @MainActor in
                self.installedApps = found
                self.isScanning = false
            }
        }
    }
}
