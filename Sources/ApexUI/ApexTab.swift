import SwiftUI

public enum ApexTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case snapping = "Snap Grid"
    case mixer = "Audio Mixer"
    case stats = "System Stats"
    case cleaner = "App Cleaner"
    case clipboard = "Clipboard"
    case shield = "FaceLock"
    case settings = "Modules"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .overview: return "sparkles"
        case .snapping: return "rectangle.split.2x2"
        case .mixer: return "speaker.wave.3.fill"
        case .stats: return "gauge.with.needle.fill"
        case .cleaner: return "trash.fill"
        case .clipboard: return "doc.on.clipboard.fill"
        case .shield: return "faceid"
        case .settings: return "slider.horizontal.3"
        }
    }
}
