import Foundation
import AppKit
import SwiftUI
import Combine

// MARK: - Hardware Notch Geometry Engine

@MainActor
public struct NotchGeometry {
    public let screen: NSScreen
    
    public var hasHardwareNotch: Bool {
        if #available(macOS 12.0, *) {
            return screen.safeAreaInsets.top > 0 &&
                   screen.auxiliaryTopLeftArea != nil &&
                   screen.auxiliaryTopRightArea != nil
        }
        return false
    }
    
    public var hardwareNotchRect: CGRect {
        if #available(macOS 12.0, *),
           let left = screen.auxiliaryTopLeftArea,
           let right = screen.auxiliaryTopRightArea {
            let notchWidth = right.minX - left.maxX
            let notchHeight = screen.safeAreaInsets.top
            let notchX = left.maxX
            let notchY = screen.frame.maxY - notchHeight
            return CGRect(x: notchX, y: notchY, width: notchWidth, height: notchHeight)
        }
        let defaultWidth: CGFloat = 208
        let defaultHeight: CGFloat = 34
        let defaultX = screen.frame.origin.x + (screen.frame.width - defaultWidth) / 2.0
        let defaultY = screen.frame.maxY - defaultHeight
        return CGRect(x: defaultX, y: defaultY, width: defaultWidth, height: defaultHeight)
    }
    
    public func windowFrame(isExpanded: Bool, wingWidth: CGFloat = 175) -> CGRect {
        let notch = hardwareNotchRect
        let height: CGFloat = isExpanded ? 104 : notch.height
        
        if hasHardwareNotch {
            let totalWidth = isExpanded ? max(notch.width + (wingWidth * 2), 540) : notch.width + (wingWidth * 2)
            let x = notch.midX - (totalWidth / 2.0)
            let y = screen.frame.maxY - height
            return CGRect(x: x, y: y, width: totalWidth, height: height)
        } else {
            let width: CGFloat = isExpanded ? 500 : 360
            let x = screen.frame.origin.x + (screen.frame.width - width) / 2.0
            let y = screen.frame.maxY - height - 8
            return CGRect(x: x, y: y, width: width, height: height)
        }
    }
}

// MARK: - Notch Window Controller

@MainActor
public final class NotchBarController: ObservableObject {
    public static let shared = NotchBarController()
    
    private var window: NSPanel?
    @Published public private(set) var isVisible: Bool = false
    @Published public var isExpanded: Bool = false {
        didSet {
            updateWindowFrame(animated: true)
        }
    }
    
    private init() {}
    
    public func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }
    
    public func show() {
        guard NSScreen.main != nil else { return }
        
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
            panel.hasShadow = false
            panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            
            let hosting = NSHostingView(rootView: NotchDynamicIslandRootView(controller: self))
            panel.contentView = hosting
            self.window = panel
        }
        
        updateWindowFrame(animated: false)
        window?.orderFrontRegardless()
        isVisible = true
    }
    
    public func hide() {
        window?.orderOut(nil)
        isVisible = false
    }
    
    public func updateWindowFrame(animated: Bool) {
        guard let mainScreen = NSScreen.main, let win = window else { return }
        let geom = NotchGeometry(screen: mainScreen)
        let targetFrame = geom.windowFrame(isExpanded: isExpanded)
        
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.28
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                win.animator().setFrame(targetFrame, display: true)
            }
        } else {
            win.setFrame(targetFrame, display: true)
        }
    }
}

// MARK: - Modern Dynamic Notch / Island Root View

public struct NotchDynamicIslandRootView: View {
    @ObservedObject public var controller: NotchBarController
    @ObservedObject private var cpu = CPUStatsEngine.shared
    @ObservedObject private var memory = MemoryStatsEngine.shared
    @ObservedObject private var battery = BatteryStatsEngine.shared
    @ObservedObject private var audio = AudioEngine.shared
    
    @State private var isHovered = false
    @State private var wavePhase: Double = 0
    @State private var timerSubscription: Timer? = nil
    
    private var hasHardwareNotch: Bool {
        if let screen = NSScreen.main {
            return NotchGeometry(screen: screen).hasHardwareNotch
        }
        return false
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            // Hardware Notch Pitch-Black Obsidian Shell
            NotchCurvedShellShape(hasHardwareNotch: hasHardwareNotch, isExpanded: controller.isExpanded)
                .fill(Color.black)
                .overlay(
                    NotchCurvedShellShape(hasHardwareNotch: hasHardwareNotch, isExpanded: controller.isExpanded)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.22),
                                    Color.white.opacity(0.04),
                                    Color.white.opacity(0.14)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.75
                        )
                )
                .shadow(
                    color: Color.black.opacity(controller.isExpanded ? 0.75 : 0.35),
                    radius: controller.isExpanded ? 24 : 10,
                    y: controller.isExpanded ? 8 : 4
                )
            
            // Dynamic Island Content
            if controller.isExpanded {
                expandedIslandView
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            } else {
                collapsedIslandView
                    .transition(.opacity)
            }
        }
        .onHover { hovering in
            withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                isHovered = hovering
                controller.isExpanded = hovering
            }
        }
        .onAppear {
            timerSubscription = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
                Task { @MainActor in
                    self.wavePhase += 0.4
                }
            }
        }
    }
    
    // MARK: - Collapsed Notch Wings
    
    private var collapsedIslandView: some View {
        HStack(spacing: 0) {
            // Left Wing: Audio wave visualizer + Master Volume
            HStack(spacing: 8) {
                // Animated sound bars
                HStack(spacing: 2.5) {
                    ForEach(0..<4) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 2.5, height: max(4, min(14, 6 + 7 * sin(wavePhase + Double(index) * 0.9))))
                    }
                }
                .frame(width: 14, height: 16)
                
                Image(systemName: audio.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(audio.isMuted ? .red : .gray)
                
                Text(audio.isMuted ? "MUTE" : "\(Int(audio.masterVolume * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.92))
                
                Spacer()
            }
            .padding(.leading, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 37.5)
            
            // Hardware Notch Mask clearance (sits right under camera)
            if hasHardwareNotch {
                Spacer()
                    .frame(width: 208, height: 37.5)
            } else {
                // Minimalist Peak Icon on non-notched screens
                Image(systemName: "triangle.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.cyan.opacity(0.85))
                    .frame(width: 40, height: 37.5)
            }
            
            // Right Wing: CPU Load + Unified RAM + Battery
            HStack(spacing: 9) {
                Spacer()
                
                // CPU Pill with glowing dot
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 5, height: 5)
                        .shadow(color: .cyan.opacity(0.9), radius: 3)
                    
                    Text(String(format: "%.0f%%", cpu.cpuLoad.totalUsage))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                // RAM Pill
                HStack(spacing: 3) {
                    Image(systemName: "memorychip")
                        .font(.system(size: 9))
                        .foregroundColor(.purple)
                    Text(String(format: "%.1fG", memory.memory.usedGB))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.92))
                }
                
                // Battery Pill
                HStack(spacing: 3) {
                    Image(systemName: battery.battery.isCharging ? "bolt.fill" : "battery.75")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(battery.battery.isCharging ? .green : (battery.battery.percentage < 20 ? .red : .gray))
                    Text("\(battery.battery.percentage)%")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(.trailing, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 37.5)
        }
        .frame(height: 37.5)
    }
    
    // MARK: - Expanded Dynamic Island HUD
    
    private var expandedIslandView: some View {
        VStack(spacing: 0) {
            // Camera Notch top clearance
            Spacer().frame(height: 38)
            
            // Interactive Vitals Bar
            HStack(spacing: 16) {
                // CPU Activity Ring & Core Count
                HStack(spacing: 9) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 4)
                        Circle()
                            .trim(from: 0, to: CGFloat(cpu.cpuLoad.totalUsage / 100.0))
                            .stroke(
                                LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        
                        Text(String(format: "%.0f", cpu.cpuLoad.totalUsage))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .frame(width: 40, height: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CPU LOAD")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .foregroundColor(.cyan)
                        Text("\(cpu.coreCount) CORES • M-CHIP")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                
                Divider()
                    .frame(height: 34)
                    .background(Color.white.opacity(0.15))
                
                // Unified RAM Gauge
                HStack(spacing: 9) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 4)
                        Circle()
                            .trim(from: 0, to: CGFloat(memory.memory.usedGB / memory.memory.totalGB))
                            .stroke(
                                LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        
                        Text(String(format: "%.0f%%", memory.memory.usagePercentage))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .frame(width: 40, height: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("UNIFIED RAM")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .foregroundColor(.purple)
                        Text(String(format: "%.1f / %.0f GB", memory.memory.usedGB, memory.memory.totalGB))
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
                
                Divider()
                    .frame(height: 34)
                    .background(Color.white.opacity(0.15))
                
                // Quick Action Buttons
                HStack(spacing: 8) {
                    Button(action: {
                        memory.purgeMemory()
                    }) {
                        VStack(spacing: 3) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                            Text("Purge")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                        .frame(width: 44, height: 42)
                        .background(Color.yellow.opacity(0.15))
                        .cornerRadius(9)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(Color.yellow.opacity(0.35), lineWidth: 0.75)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        ApexKernel.shared.toggleHUD()
                    }) {
                        VStack(spacing: 3) {
                            Image(systemName: "triangle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.cyan)
                            Text("Apex")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.cyan)
                        }
                        .frame(width: 44, height: 42)
                        .background(Color.cyan.opacity(0.15))
                        .cornerRadius(9)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(Color.cyan.opacity(0.35), lineWidth: 0.75)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .frame(height: 58)
            
            Spacer().frame(height: 8)
        }
        .frame(height: 104)
    }
}

// MARK: - Notch Curved Shape

public struct NotchCurvedShellShape: Shape {
    public let hasHardwareNotch: Bool
    public let isExpanded: Bool
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let bottomRadius: CGFloat = isExpanded ? 24 : 14
        
        if hasHardwareNotch && !isExpanded {
            // Cutout top with rounded bottom corners matching Apple hardware notch
            path.addRoundedRect(
                in: rect,
                cornerSize: CGSize(width: bottomRadius, height: bottomRadius),
                style: .continuous
            )
        } else {
            // Smooth continuous capsule / squircle
            path.addRoundedRect(
                in: rect,
                cornerSize: CGSize(width: bottomRadius, height: bottomRadius),
                style: .continuous
            )
        }
        
        return path
    }
}
