import Foundation
import AppKit
import SwiftUI

@MainActor
public final class NotchBarController: ObservableObject {
    public static let shared = NotchBarController()
    
    private var window: NSPanel?
    @Published public private(set) var isVisible: Bool = false
    
    private init() {}
    
    public func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }
    
    public func show() {
        guard let mainScreen = NSScreen.main else { return }
        
        if window == nil {
            let panel = NSPanel(
                contentRect: .zero,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.level = .statusBar
            panel.hasShadow = true
            panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            
            let hosting = NSHostingView(rootView: NotchHUDView())
            panel.contentView = hosting
            self.window = panel
        }
        
        let screenFrame = mainScreen.frame
        let width: CGFloat = 320
        let height: CGFloat = 34
        let notchX = screenFrame.origin.x + (screenFrame.width - width) / 2.0
        let notchY = screenFrame.origin.y + screenFrame.height - height
        
        window?.setFrame(CGRect(x: notchX, y: notchY, width: width, height: height), display: true)
        window?.orderFrontRegardless()
        isVisible = true
    }
    
    public func hide() {
        window?.orderOut(nil)
        isVisible = false
    }
}

public struct NotchHUDView: View {
    @ObservedObject private var cpu = CPUStatsEngine.shared
    @ObservedObject private var memory = MemoryStatsEngine.shared
    @ObservedObject private var battery = BatteryStatsEngine.shared
    
    public var body: some View {
        HStack(spacing: 12) {
            // CPU Pill
            HStack(spacing: 5) {
                Image(systemName: "cpu")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.cyan)
                Text(String(format: "%.0f%%", cpu.cpuLoad.totalUsage))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.4))
            .cornerRadius(8)
            
            Spacer()
            
            // Peak symbol
            Image(systemName: "triangle.fill")
                .font(.system(size: 8))
                .foregroundColor(Color.cyan.opacity(0.8))
            
            Spacer()
            
            // RAM Pill
            HStack(spacing: 5) {
                Image(systemName: "memorychip")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.purple)
                Text(String(format: "%.1fG", memory.memory.usedGB))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.4))
            .cornerRadius(8)
            
            // Battery Pill
            HStack(spacing: 4) {
                Image(systemName: battery.battery.isCharging ? "battery.100.bolt" : "battery.75")
                    .font(.system(size: 11))
                    .foregroundColor(battery.battery.percentage < 20 ? .red : .green)
                Text("\(battery.battery.percentage)%")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.4))
            .cornerRadius(8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
        .frame(height: 32)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}
