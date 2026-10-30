import Foundation
import CoreGraphics

public enum WindowSnapAction: String, CaseIterable, Identifiable {
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case topLeftQuarter
    case topRightQuarter
    case bottomLeftQuarter
    case bottomRightQuarter
    case leftThird
    case centerThird
    case rightThird
    case leftTwoThirds
    case rightTwoThirds
    case maximize
    case center
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .leftHalf: return "Left Half"
        case .rightHalf: return "Right Half"
        case .topHalf: return "Top Half"
        case .bottomHalf: return "Bottom Half"
        case .topLeftQuarter: return "Top-Left"
        case .topRightQuarter: return "Top-Right"
        case .bottomLeftQuarter: return "Bottom-Left"
        case .bottomRightQuarter: return "Bottom-Right"
        case .leftThird: return "Left Third"
        case .centerThird: return "Center Third"
        case .rightThird: return "Right Third"
        case .leftTwoThirds: return "Left 2/3"
        case .rightTwoThirds: return "Right 2/3"
        case .maximize: return "Maximize"
        case .center: return "Center"
        }
    }
    
    public var iconName: String {
        switch self {
        case .leftHalf: return "rectangle.leadinghalf.filled"
        case .rightHalf: return "rectangle.trailinghalf.filled"
        case .topHalf: return "rectangle.tophalf.filled"
        case .bottomHalf: return "rectangle.bottomhalf.filled"
        case .topLeftQuarter: return "rectangle.inset.topleft.filled"
        case .topRightQuarter: return "rectangle.inset.topright.filled"
        case .bottomLeftQuarter: return "rectangle.inset.bottomleft.filled"
        case .bottomRightQuarter: return "rectangle.inset.bottomright.filled"
        case .leftThird: return "rectangle.split.3x1"
        case .centerThird: return "rectangle.center.inset.filled"
        case .rightThird: return "rectangle.split.3x1"
        case .leftTwoThirds: return "rectangle.split.2x1"
        case .rightTwoThirds: return "rectangle.split.2x1"
        case .maximize: return "arrow.up.left.and.arrow.down.right"
        case .center: return "viewfinder"
        }
    }
    
    public var shortcutDescription: String {
        switch self {
        case .leftHalf: return "⌃⌥←"
        case .rightHalf: return "⌃⌥→"
        case .topHalf: return "⌃⌥↑"
        case .bottomHalf: return "⌃⌥↓"
        case .topLeftQuarter: return "⌃⌥U"
        case .topRightQuarter: return "⌃⌥I"
        case .bottomLeftQuarter: return "⌃⌥J"
        case .bottomRightQuarter: return "⌃⌥K"
        case .leftThird: return "⌃⌥D"
        case .centerThird: return "⌃⌥F"
        case .rightThird: return "⌃⌥G"
        case .leftTwoThirds: return "⌃⌥E"
        case .rightTwoThirds: return "⌃⌥T"
        case .maximize: return "⌃⌥↩"
        case .center: return "⌃⌥C"
        }
    }
}
