import SwiftUI

public struct AppCleanerHUDView: View {
    @ObservedObject private var scanner = AppScanner.shared
    @State private var searchText = ""
    @State private var selectedApp: InstalledApp?
    @State private var residualItems: [AppResidualItem] = []
    @State private var isScanningResidue = false
    @State private var cleanResultText: String?
    
    private var filteredApps: [InstalledApp] {
        if searchText.isEmpty {
            return scanner.installedApps
        }
        return scanner.installedApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var totalSelectedBytes: Int64 {
        residualItems.filter { $0.isSelected }.reduce(0) { $0 + $1.sizeBytes }
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            // Left: Installed Apps List
            VStack(spacing: 10) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search Applications...", text: $searchText)
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
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.06))
                .cornerRadius(8)
                
                // Apps List
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(filteredApps) { app in
                            Button(action: { selectApp(app) }) {
                                HStack(spacing: 8) {
                                    if let icon = app.icon {
                                        Image(nsImage: icon)
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                    } else {
                                        Image(systemName: "app.fill")
                                            .frame(width: 20, height: 20)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(app.name)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        Text(app.version)
                                            .font(.system(size: 9))
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(selectedApp?.id == app.id ? Color.apexCyan.opacity(0.25) : Color.clear)
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(width: 170)
            .padding(12)
            .background(Color.black.opacity(0.2))
            
            Divider().background(Color.white.opacity(0.1))
            
            // Right: Residual Inspection & Cleaning Pane
            VStack(spacing: 12) {
                if let app = selectedApp {
                    // App Header
                    HStack(spacing: 10) {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 32, height: 32)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.name)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Text(app.bundleIdentifier)
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .glassCard()
                    
                    if isScanningResidue {
                        VStack(spacing: 10) {
                            ProgressView()
                            Text("Deep scanning cache & preferences...")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Residual Tree
                        ScrollView {
                            LazyVStack(spacing: 6) {
                                ForEach($residualItems) { $item in
                                    HStack(spacing: 8) {
                                        Toggle("", isOn: $item.isSelected)
                                            .toggleStyle(.checkbox)
                                            .labelsHidden()
                                        
                                        Image(systemName: item.category.iconName)
                                            .font(.system(size: 11))
                                            .foregroundColor(.apexCyan)
                                        
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(item.name)
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                            Text(item.category.rawValue)
                                                .font(.system(size: 9))
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(item.formattedSize)
                                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                            .foregroundColor(.apexPurple)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(6)
                                }
                            }
                        }
                        
                        // Action Footer
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("SELECTED TO PURGE")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(ByteCountFormatter.string(fromByteCount: totalSelectedBytes, countStyle: .file))
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Button(action: performDeepClean) {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash.fill")
                                    Text("Safe Move to Trash")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.apexCoral)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                        .glassCard(borderColor: Color.apexCoral.opacity(0.3))
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "trash.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.6))
                        Text("Select an application from the left to deep scan its cache, preferences and containers.")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(12)
        }
        .onAppear {
            if selectedApp == nil, let first = scanner.installedApps.first {
                selectApp(first)
            }
        }
    }
    
    private func selectApp(_ app: InstalledApp) {
        selectedApp = app
        isScanningResidue = true
        cleanResultText = nil
        
        Task.detached(priority: .userInitiated) {
            let items = DeepResidualFinder.shared.findResidue(for: app)
            await MainActor.run {
                self.residualItems = items
                self.isScanningResidue = false
            }
        }
    }
    
    private func performDeepClean() {
        let itemsToTrash = residualItems
        DeepResidualFinder.shared.trashItems(itemsToTrash) { count, bytes in
            Task { @MainActor in
                self.cleanResultText = "Trashed \(count) items (\(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)))"
                self.scanner.scan()
                self.residualItems.removeAll(where: { $0.isSelected })
            }
        }
    }
}
