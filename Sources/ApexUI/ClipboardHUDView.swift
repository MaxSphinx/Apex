import SwiftUI

public struct ClipboardHUDView: View {
    @ObservedObject private var clipboard = ClipboardEngine.shared
    @ObservedObject private var shelfState = FileShelfState.shared
    @State private var searchText = ""
    @State private var copiedFeedbackId: UUID?
    
    private var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboard.items
        }
        return clipboard.items.filter {
            $0.textContent?.localizedCaseInsensitiveContains(searchText) == true ||
            $0.previewTitle.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Controls Header
            HStack(spacing: 10) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search clipboard history...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.06))
                .cornerRadius(8)
                
                // Toggle Shelf Button
                Button(action: { ShelfWindowController.shared.toggle() }) {
                    HStack(spacing: 5) {
                        Image(systemName: "tray.and.arrow.down.fill")
                        Text(ShelfWindowController.shared.isVisible ? "Hide Shelf" : "Open Shelf")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.apexPurple.opacity(0.2))
                    .foregroundColor(.apexPurple)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                // Clear Unpinned Button
                Button(action: { clipboard.clearAll() }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .padding(7)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Clipboard List
            if filteredItems.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 36))
                        .foregroundColor(.gray.opacity(0.5))
                    Text(searchText.isEmpty ? "Clipboard is empty" : "No matching items")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredItems) { item in
                            HStack(spacing: 10) {
                                // Type Icon
                                Image(systemName: iconName(for: item.type))
                                    .font(.system(size: 13))
                                    .foregroundColor(.apexCyan)
                                    .frame(width: 20)
                                
                                // Content Preview
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.previewTitle)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                    
                                    Text(item.timestamp, style: .time)
                                        .font(.system(size: 9))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                // Pin Button
                                Button(action: { clipboard.togglePin(item) }) {
                                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                                        .font(.system(size: 11))
                                        .foregroundColor(item.isPinned ? .yellow : .gray)
                                }
                                .buttonStyle(.plain)
                                
                                // Copy Button
                                Button(action: {
                                    clipboard.copyToPasteboard(item)
                                    copiedFeedbackId = item.id
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        if copiedFeedbackId == item.id {
                                            copiedFeedbackId = nil
                                        }
                                    }
                                }) {
                                    HStack(spacing: 3) {
                                        Image(systemName: copiedFeedbackId == item.id ? "checkmark" : "doc.on.doc")
                                        Text(copiedFeedbackId == item.id ? "Copied" : "Copy")
                                    }
                                    .font(.system(size: 10, weight: .semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(copiedFeedbackId == item.id ? Color.apexEmerald.opacity(0.25) : Color.white.opacity(0.08))
                                    .foregroundColor(copiedFeedbackId == item.id ? .apexEmerald : .white)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                                
                                // Delete Button
                                Button(action: { clipboard.removeItem(item) }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .glassCard(borderColor: item.isPinned ? Color.yellow.opacity(0.3) : Color.apexBorder)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
    }
    
    private func iconName(for type: ClipboardItemType) -> String {
        switch type {
        case .text: return "text.alignleft"
        case .image: return "photo.fill"
        case .fileURL: return "folder.fill"
        case .color: return "paintpalette.fill"
        }
    }
}
