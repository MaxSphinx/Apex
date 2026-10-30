import Foundation
import AppKit
import SwiftUI
import UniformTypeIdentifiers

public struct ParkedFileItem: Identifiable, Hashable, @unchecked Sendable {
    public let id: String
    public let url: URL
    public let name: String
    public let icon: NSImage
    public let formattedSize: String
    
    public init(url: URL) {
        self.id = url.path
        self.url = url
        self.name = url.lastPathComponent
        self.icon = NSWorkspace.shared.icon(forFile: url.path)
        
        let attr = try? FileManager.default.attributesOfItem(atPath: url.path)
        let size = (attr?[.size] as? Int64) ?? 0
        self.formattedSize = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

@MainActor
public final class FileShelfState: ObservableObject {
    public static let shared = FileShelfState()
    
    @Published public var parkedFiles: [ParkedFileItem] = []
    
    private init() {}
    
    public func addFiles(_ urls: [URL]) {
        for url in urls {
            if !parkedFiles.contains(where: { $0.url == url }) {
                parkedFiles.append(ParkedFileItem(url: url))
            }
        }
    }
    
    public func removeFile(_ item: ParkedFileItem) {
        parkedFiles.removeAll(where: { $0.id == item.id })
    }
    
    public func clearAll() {
        parkedFiles.removeAll()
    }
}

@MainActor
public final class ShelfWindowController: ObservableObject {
    public static let shared = ShelfWindowController()
    
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
        guard let screen = NSScreen.main else { return }
        
        if window == nil {
            let panel = NSPanel(
                contentRect: .zero,
                styleMask: [.titled, .nonactivatingPanel, .closable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.level = .floating
            panel.titleVisibility = .hidden
            panel.titlebarAppearsTransparent = true
            panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            
            let hosting = NSHostingView(rootView: ShelfHUDContainerView())
            panel.contentView = hosting
            self.window = panel
        }
        
        let width: CGFloat = 260
        let height: CGFloat = 340
        let x = screen.visibleFrame.maxX - width - 20
        let y = screen.visibleFrame.midY - (height / 2.0)
        
        window?.setFrame(CGRect(x: x, y: y, width: width, height: height), display: true)
        window?.orderFrontRegardless()
        isVisible = true
    }
    
    public func hide() {
        window?.orderOut(nil)
        isVisible = false
    }
}

public struct ShelfHUDContainerView: View {
    @ObservedObject private var shelfState = FileShelfState.shared
    @State private var isTargeted: Bool = false
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "tray.and.arrow.down.fill")
                    .foregroundColor(.cyan)
                    .font(.system(size: 13, weight: .bold))
                Text("Apex File Shelf")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                if !shelfState.parkedFiles.isEmpty {
                    Button(action: { shelfState.clearAll() }) {
                        Text("Clear")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
                Button(action: { ShelfWindowController.shared.hide() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.35))
            
            Divider().background(Color.white.opacity(0.1))
            
            // Drop Zone / Items
            if shelfState.parkedFiles.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: isTargeted ? "arrow.down.circle.fill" : "plus.viewfinder")
                        .font(.system(size: 36))
                        .foregroundColor(isTargeted ? .cyan : .gray.opacity(0.7))
                    Text("Drop files here to park")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    Text("Drag to any space or app later")
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.6))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isTargeted ? Color.cyan.opacity(0.1) : Color.clear)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(shelfState.parkedFiles) { item in
                            HStack(spacing: 10) {
                                Image(nsImage: item.icon)
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Text(item.formattedSize)
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Button(action: { shelfState.removeFile(item) }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(8)
                            .onDrag {
                                NSItemProvider(object: item.url as NSURL)
                            }
                        }
                    }
                    .padding(10)
                }
            }
        }
        .frame(minWidth: 240, minHeight: 300)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isTargeted ? Color.cyan : Color.white.opacity(0.15), lineWidth: 1.5)
                )
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        Task { @MainActor in
                            shelfState.addFiles([url])
                        }
                    }
                }
            }
            return true
        }
    }
}
