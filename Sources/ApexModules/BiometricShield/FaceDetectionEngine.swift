import Foundation
import AVFoundation
import Vision
import AppKit

@MainActor
public final class FaceDetectionEngine: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    public static let shared = FaceDetectionEngine()
    
    @Published public private(set) var isFacePresent: Bool = false
    @Published public private(set) var isScanning: Bool = false
    
    nonisolated(unsafe) private var captureSession: AVCaptureSession?
    nonisolated(unsafe) private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.apex.facedetection.session")
    nonisolated(unsafe) private var lastDetectionTime = Date()
    
    private override init() {
        super.init()
    }
    
    public func startCapture() {
        guard captureSession == nil else {
            if captureSession?.isRunning == false {
                sessionQueue.async { [weak self] in
                    self?.captureSession?.startRunning()
                }
            }
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let session = AVCaptureSession()
            session.sessionPreset = .low
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) ??
                               AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                return
            }
            
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            
            if session.canAddOutput(self.videoOutput) {
                session.addOutput(self.videoOutput)
            }
            
            session.startRunning()
            self.captureSession = session
            
            Task { @MainActor in
                self.isScanning = true
            }
        }
    }
    
    public func stopCapture() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession?.isRunning == true {
                self.captureSession?.stopRunning()
            }
            self.captureSession = nil
            Task { @MainActor in
                self.isScanning = false
                self.isFacePresent = false
            }
        }
    }
    
    public nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard Date().timeIntervalSince(lastDetectionTime) > 0.5 else { return }
        lastDetectionTime = Date()
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectFaceRectanglesRequest { req, error in
            guard error == nil else { return }
            let results = req.results as? [VNFaceObservation] ?? []
            let hasFace = !results.isEmpty
            
            Task { @MainActor in
                FaceDetectionEngine.shared.isFacePresent = hasFace
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([request])
    }
}
