import Foundation
import AppKit
import Vision

@MainActor
public final class ScreenOCREngine: ObservableObject {
    public static let shared = ScreenOCREngine()
    
    @Published public private(set) var isRecognizing: Bool = false
    @Published public private(set) var lastRecognizedText: String? = nil
    
    private init() {}
    
    public func startInteractiveOCR(completion: (@Sendable (String?) -> Void)? = nil) {
        guard !isRecognizing else { return }
        isRecognizing = true
        
        let tempPath = "/tmp/apex_ocr_snapshot.png"
        try? FileManager.default.removeItem(atPath: tempPath)
        
        // Execute macOS interactive screen selection capture
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let process = Process()
            process.launchPath = "/usr/sbin/screencapture"
            process.arguments = ["-i", "-x", tempPath]
            process.standardOutput = Pipe()
            process.standardError = Pipe()
            
            try? process.run()
            process.waitUntilExit()
            
            guard FileManager.default.fileExists(atPath: tempPath),
                  let image = NSImage(contentsOfFile: tempPath),
                  let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                Task { @MainActor in
                    self?.isRecognizing = false
                    completion?(nil)
                }
                return
            }
            
            // Perform Apple Vision offline OCR
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    Task { @MainActor in
                        self?.isRecognizing = false
                        completion?(nil)
                    }
                    return
                }
                
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                let text = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                
                Task { @MainActor in
                    self?.isRecognizing = false
                    if !text.isEmpty {
                        self?.lastRecognizedText = text
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(text, forType: .string)
                    }
                    completion?(text.isEmpty ? nil : text)
                }
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
            
            try? FileManager.default.removeItem(atPath: tempPath)
        }
    }
}
