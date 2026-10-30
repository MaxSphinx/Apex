import Foundation
import AVFoundation
import Vision
import CoreVideo
import AppKit

@MainActor
public final class BiometricFaceEngine: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    public static let shared = BiometricFaceEngine()

    @Published public private(set) var isScanning: Bool = false
    @Published public private(set) var isFacePresent: Bool = false
    @Published public private(set) var enrolledVectorsCount: Int = 0

    nonisolated(unsafe) private var captureSession: AVCaptureSession?
    nonisolated(unsafe) private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "io.github.maxsphinx.apex.biometrics.session", qos: .userInitiated)

    private var enrolledVectors: [[Float]] = []
    private var scanCompletion: ((Bool, Float?, NSImage?) -> Void)?
    nonisolated(unsafe) private var scanTimer: DispatchSourceTimer?
    private var lastSnapshot: NSImage?
    private var latestIntruderPhoto: NSImage?
    private var hasDetectedFace = false

    public var similarityThreshold: Float = 0.22

    private override init() {
        super.init()
        loadEnrolledVectors()
    }

    public func loadEnrolledVectors() {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let apexPath = home.appendingPathComponent(".apex/owner_face_vectors.json").path
        let facelockPath = home.appendingPathComponent(".facelock/owner_face_vectors.json").path

        var targetPath: String?
        if fm.fileExists(atPath: apexPath) {
            targetPath = apexPath
        } else if fm.fileExists(atPath: facelockPath) {
            targetPath = facelockPath
        }

        guard let path = targetPath,
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let vectors = json["vectors"] as? [[Double]] else {
            self.enrolledVectors = []
            self.enrolledVectorsCount = 0
            return
        }

        self.enrolledVectors = vectors.map { $0.map { Float($0) } }
        self.enrolledVectorsCount = self.enrolledVectors.count
    }

    public func saveEnrolledVectors(_ vectors: [[Float]]) {
        self.enrolledVectors = vectors
        self.enrolledVectorsCount = vectors.count

        let home = FileManager.default.homeDirectoryForCurrentUser
        let dir = home.appendingPathComponent(".apex")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileURL = dir.appendingPathComponent("owner_face_vectors.json")

        let doubleVectors = vectors.map { $0.map { Double($0) } }
        let payload: [String: Any] = [
            "updatedAt": ISO8601DateFormatter().string(from: Date()),
            "vectors": doubleVectors,
            "version": "1.0.0"
        ]

        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]) {
            try? data.write(to: fileURL)
        }
    }

    public func addEnrolledVector(_ vector: [Float]) {
        guard vector.count == 128 else { return }
        var current = enrolledVectors
        current.append(vector)
        saveEnrolledVectors(current)
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
            session.sessionPreset = .vga640x480

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) ??
                               AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                return
            }

            if session.canAddInput(input) {
                session.addInput(input)
            }

            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
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
            self.scanTimer?.cancel()
            self.scanTimer = nil
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

    public func verifyOwner(timeout: Double = 1.5, completion: @escaping @MainActor (Bool, Float?, NSImage?) -> Void) {
        startCapture()

        self.scanCompletion = { success, dist, photo in
            Task { @MainActor in
                completion(success, dist, photo)
            }
        }

        scanTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: sessionQueue)
        timer.schedule(deadline: .now() + timeout)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                self.finishVerification(success: false, distance: 1.0, intruderPhoto: self.latestIntruderPhoto ?? self.lastSnapshot)
            }
        }
        self.scanTimer = timer
        timer.resume()
    }

    private func finishVerification(success: Bool, distance: Float?, intruderPhoto: NSImage?) {
        scanTimer?.cancel()
        scanTimer = nil
        let cb = scanCompletion
        scanCompletion = nil
        cb?(success, distance, intruderPhoto)
    }

    public nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Keep snapshot
        let ci = CIImage(cvPixelBuffer: pixelBuffer)
        let rep = NSCIImageRep(ciImage: ci)
        let snapshot = NSImage(size: rep.size)
        snapshot.addRepresentation(rep)

        Task { @MainActor in
            self.lastSnapshot = snapshot
        }

        let faceReq = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([faceReq])

        var faces = faceReq.results ?? []

        // Low-light compensation fallback if needed
        if faces.isEmpty {
            if let exp = CIFilter(name: "CIExposureAdjust") {
                exp.setValue(ci, forKey: kCIInputImageKey)
                exp.setValue(1.5, forKey: kCIInputEVKey)
                if let boosted = exp.outputImage {
                    let lowReq = VNDetectFaceRectanglesRequest()
                    let lowHandler = VNImageRequestHandler(ciImage: boosted, options: [:])
                    try? lowHandler.perform([lowReq])
                    faces = lowReq.results ?? []
                }
            }
        }

        let faceDetected = !faces.isEmpty
        Task { @MainActor in
            self.isFacePresent = faceDetected
        }

        guard faceDetected else { return }

        // Sort by area (largest face in foreground)
        let sorted = faces.sorted { ($0.boundingBox.width * $0.boundingBox.height) > ($1.boundingBox.width * $1.boundingBox.height) }
        guard let primaryFace = sorted.first else { return }

        // Extract 128-D vector
        guard let (candidateVec, faceObs) = FaceprintExtractor.shared.extractVector(from: pixelBuffer, faceObservation: primaryFace) else {
            return
        }

        // Crop intruder photo
        let intruderFace = cropFaceImage(ciImage: ci, boundingBox: faceObs.boundingBox)

        Task { @MainActor in
            self.latestIntruderPhoto = intruderFace

            // Compare against enrolled vectors
            if self.enrolledVectors.isEmpty {
                // Presence detection fallback if no faces enrolled
                self.finishVerification(success: true, distance: 0.0, intruderPhoto: nil)
                return
            }

            let distances = self.enrolledVectors.map { FaceprintExtractor.cosineDistance(candidateVec, $0) }.sorted()
            let minDistance = distances.first ?? 1.0

            if minDistance <= self.similarityThreshold {
                self.finishVerification(success: true, distance: minDistance, intruderPhoto: nil)
            }
        }
    }

    private nonisolated func cropFaceImage(ciImage: CIImage, boundingBox: CGRect) -> NSImage? {
        let extent = ciImage.extent
        let w = extent.width
        let h = extent.height
        let x = boundingBox.origin.x * w
        let y = boundingBox.origin.y * h
        let bw = boundingBox.width * w
        let bh = boundingBox.height * h

        let padX = bw * 0.35
        let padY = bh * 0.45
        let cropRect = CGRect(x: max(0, x - padX), y: max(0, y - padY), width: min(w, bw + padX * 2), height: min(h, bh + padY * 2))

        let cropped = ciImage.cropped(to: cropRect)
        let rep = NSCIImageRep(ciImage: cropped)
        let img = NSImage(size: rep.size)
        img.addRepresentation(rep)
        return img
    }
}
