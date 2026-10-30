import Foundation
import AppKit

func generateApexIcon(size: Int) -> NSImage {
    let imgSize = NSSize(width: size, height: size)
    let image = NSImage(size: imgSize, flipped: false) { rect in
        let context = NSGraphicsContext.current?.cgContext
        
        // Background rounded squircle / icon canvas
        let cornerRadius = CGFloat(size) * 0.22
        let bgRect = NSRect(x: 0, y: 0, width: size, height: size).insetBy(dx: CGFloat(size) * 0.04, dy: CGFloat(size) * 0.04)
        let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)
        
        // Deep obsidian-space dark gradient
        let gradient = NSGradient(
            colors: [
                NSColor(red: 0.07, green: 0.08, blue: 0.12, alpha: 1.0),
                NSColor(red: 0.02, green: 0.03, blue: 0.05, alpha: 1.0)
            ]
        )
        gradient?.draw(in: bgPath, angle: -45)
        
        // Subtle cyber glow border
        bgPath.lineWidth = max(1.0, CGFloat(size) * 0.015)
        NSColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 0.4).setStroke()
        bgPath.stroke()
        
        // Apex Peak (Triangle)
        let midX = CGFloat(size) / 2.0
        let peakY = CGFloat(size) * 0.72
        let baseY = CGFloat(size) * 0.28
        let halfWidth = CGFloat(size) * 0.30
        
        let peakPath = NSBezierPath()
        peakPath.move(to: NSPoint(x: midX, y: peakY))
        peakPath.line(to: NSPoint(x: midX + halfWidth, y: baseY))
        peakPath.line(to: NSPoint(x: midX - halfWidth, y: baseY))
        peakPath.close()
        
        peakPath.lineJoinStyle = .round
        peakPath.lineWidth = max(2.0, CGFloat(size) * 0.04)
        
        // Neon cyan stroke
        NSColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 0.95).setStroke()
        peakPath.stroke()
        
        // Center Neural Core Node
        let coreRadius = CGFloat(size) * 0.065
        let coreRect = NSRect(
            x: midX - coreRadius,
            y: baseY + (peakY - baseY) * 0.35 - coreRadius,
            width: coreRadius * 2,
            height: coreRadius * 2
        )
        let corePath = NSBezierPath(ovalIn: coreRect)
        NSColor(red: 0.65, green: 0.35, blue: 1.0, alpha: 0.95).setFill()
        corePath.fill()
        
        return true
    }
    return image
}

let iconsetPath = "/tmp/Apex.iconset"
try? FileManager.default.removeItem(atPath: iconsetPath)
try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes = [16, 32, 64, 128, 256, 512, 1024]
for s in sizes {
    let img = generateApexIcon(size: s)
    if let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) {
        let filename = s == 1024 ? "icon_512x512@2x.png" : "icon_\(s)x\(s).png"
        try? png.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(filename)"))
        if s <= 512 {
            let retinaName = "icon_\(s/2)x\(s/2)@2x.png"
            if s/2 > 0 {
                try? png.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(retinaName)"))
            }
        }
    }
}

print("Iconset generated at \(iconsetPath)")
