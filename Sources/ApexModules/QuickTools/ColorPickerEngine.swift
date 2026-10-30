import Foundation
import AppKit

@MainActor
public final class ColorPickerEngine: ObservableObject {
    public static let shared = ColorPickerEngine()
    
    private var sampler: NSColorSampler?
    @Published public private(set) var lastSampledColor: NSColor?
    @Published public private(set) var lastHexValue: String?
    
    public enum ColorFormat: String, CaseIterable, Identifiable {
        case hex = "HEX (#RRGGBB)"
        case rgb = "RGB (r, g, b)"
        case swiftUI = "SwiftUI Color"
        
        public var id: String { rawValue }
    }
    
    @Published public var format: ColorFormat = .hex
    
    private init() {}
    
    public func pickColor(completion: (@Sendable (String?) -> Void)? = nil) {
        guard sampler == nil else { return }
        
        let newSampler = NSColorSampler()
        self.sampler = newSampler
        
        newSampler.show { [weak self] color in
            Task { @MainActor in
                self?.sampler = nil
                guard let color = color, let srgb = color.usingColorSpace(.sRGB) else {
                    completion?(nil)
                    return
                }
                
                self?.lastSampledColor = srgb
                
                let r = Int(round(srgb.redComponent * 255))
                let g = Int(round(srgb.greenComponent * 255))
                let b = Int(round(srgb.blueComponent * 255))
                let hex = String(format: "#%02X%02X%02X", r, g, b)
                self?.lastHexValue = hex
                
                let formatted: String
                switch self?.format ?? .hex {
                case .hex:
                    formatted = hex
                case .rgb:
                    formatted = "rgb(\(r), \(g), \(b))"
                case .swiftUI:
                    formatted = String(format: "Color(red: %.2f, green: %.2f, blue: %.2f)", srgb.redComponent, srgb.greenComponent, srgb.blueComponent)
                }
                
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(formatted, forType: .string)
                completion?(formatted)
            }
        }
    }
}
