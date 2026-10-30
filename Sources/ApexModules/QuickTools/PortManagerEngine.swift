import Foundation
import Combine

public struct PortEntry: Identifiable, Sendable {
    public var id: String { "\(pid)_\(port)" }
    public let command: String
    public let pid: Int32
    public let user: String
    public let port: Int
    public let address: String
}

@MainActor
public final class PortManagerEngine: ObservableObject {
    public static let shared = PortManagerEngine()
    
    @Published public private(set) var entries: [PortEntry] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public var filterText: String = ""
    
    public var filteredEntries: [PortEntry] {
        let query = filterText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return entries }
        return entries.filter {
            "\($0.port) \($0.command) \($0.pid) \($0.user) \($0.address)".lowercased().contains(query)
        }
    }
    
    private init() {}
    
    public func refresh() {
        guard !isLoading else { return }
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let task = Process()
            task.launchPath = "/usr/sbin/lsof"
            task.arguments = ["-nP", "-iTCP", "-sTCP:LISTEN"]
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = Pipe()
            
            try? task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            
            let output = String(data: data, encoding: .utf8) ?? ""
            let parsed = Self.parseLsofOutput(output)
            
            Task { @MainActor in
                self?.entries = parsed
                self?.isLoading = false
            }
        }
    }
    
    public func terminateProcess(pid: Int32, force: Bool = true) {
        kill(pid, force ? SIGKILL : SIGTERM)
        // Refresh shortly after kill
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refresh()
        }
    }
    
    private nonisolated static func parseLsofOutput(_ output: String) -> [PortEntry] {
        var results: [PortEntry] = []
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines.dropFirst() {
            let tokens = line.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard tokens.count >= 9 else { continue }
            
            let command = tokens[0]
            guard let pid = Int32(tokens[1]) else { continue }
            let user = tokens[2]
            let nameField = tokens[8]
            
            // Format: *:3000 or 127.0.0.1:8080
            if let colonIndex = nameField.lastIndex(of: ":") {
                let address = String(nameField[..<colonIndex])
                let portStr = String(nameField[nameField.index(after: colonIndex)...])
                if let port = Int(portStr) {
                    let entry = PortEntry(command: command, pid: pid, user: user, port: port, address: address)
                    results.append(entry)
                }
            }
        }
        
        return results.sorted { $0.port < $1.port }
    }
}
