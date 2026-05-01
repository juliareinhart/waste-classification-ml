import SwiftUI
import AVFoundation
import CoreML
import UIKit
import Combine

final class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()

    @Published var detectionBox: DetectionBox? = nil
    @Published var detectedLabel: String = ""
    @Published var detectedScore: Float = 0.0
    @Published var status: String = "Starting camera..."

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoOutputQueue = DispatchQueue(label: "camera.video.output.queue")
    private var isProcessingFrame = false

    private let modelInputSize = CGSize(width: 640, height: 640)
    
    private let ciContext = CIContext()

    let classNames = [
        "Cardboard",
        "Food Organics",
        "Glass",
        "Metal",
        "Miscellaneous Trash",
        "Paper",
        "Plastic",
        "Textile Trash",
        "Vegetation"
    ]

    func resizePixelBuffer(_ pixelBuffer: CVPixelBuffer, width: Int, height: Int) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let sx = CGFloat(width) / CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let sy = CGFloat(height) / CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let resizedImage = ciImage.transformed(by: CGAffineTransform(scaleX: sx, y: sy))

        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA
        ]

        var outputPixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &outputPixelBuffer
        )

        guard status == kCVReturnSuccess, let outputPixelBuffer else {
            return nil
        }

        ciContext.render(resizedImage, to: outputPixelBuffer)
        return outputPixelBuffer
    }
    
    func start() {
        checkPermissionAndConfigure()
    }

    func stop() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    private func checkPermissionAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.configureSession()
                } else {
                    DispatchQueue.main.async {
                        self.status = "Camera permission denied."
                    }
                }
            }
        default:
            DispatchQueue.main.async {
                self.status = "Camera permission denied."
            }
        }
    }

    private func configureSession() {
        sessionQueue.async {
            guard self.session.inputs.isEmpty else {
                if !self.session.isRunning {
                    self.session.startRunning()
                }
                return
            }

            self.session.beginConfiguration()

            if self.session.canSetSessionPreset(.high) {
                self.session.sessionPreset = .high
            }

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                DispatchQueue.main.async {
                    self.status = "No back camera found."
                }
                self.session.commitConfiguration()
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                } else {
                    DispatchQueue.main.async {
                        self.status = "Could not add camera input."
                    }
                    self.session.commitConfiguration()
                    return
                }
            } catch {
                DispatchQueue.main.async {
                    self.status = "Camera input error: \(error.localizedDescription)"
                }
                self.session.commitConfiguration()
                return
            }

            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            output.setSampleBufferDelegate(self, queue: self.videoOutputQueue)

            if self.session.canAddOutput(output) {
                self.session.addOutput(output)
            } else {
                DispatchQueue.main.async {
                    self.status = "Could not add video output."
                }
                self.session.commitConfiguration()
                return
            }

            if let connection = output.connection(with: .video), connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }

            self.session.commitConfiguration()
            self.session.startRunning()

            DispatchQueue.main.async {
                self.status = "Camera running."
            }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !isProcessingFrame else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        guard let resizedPixelBuffer = resizePixelBuffer(pixelBuffer, width: 640, height: 640) else {
            DispatchQueue.main.async {
                self.status = "Failed to resize camera frame."
            }
            return
        }

        isProcessingFrame = true
        defer { isProcessingFrame = false }

        do {
            let config = MLModelConfiguration()
            let model = try best(configuration: config)
            let output = try model.prediction(image: resizedPixelBuffer)
            let candidates = findCandidates(in: output.var_910, threshold: 0.4)
            let nmsResults = applyNMS(to: candidates, iouThreshold: 0.5)

            guard let result = nmsResults.first else {
                DispatchQueue.main.async {
                    self.detectionBox = nil
                    self.detectedLabel = ""
                    self.detectedScore = 0.0
                    self.status = "No confident detection."
                }
                return
            }

            let rawWidth = CGFloat(result.w)
            let rawHeight = CGFloat(result.h)
            let widthScale = min(1.0, 640.0 / rawWidth)
            let heightScale = min(1.0, 640.0 / rawHeight)
            let tuning: CGFloat = 0.85

            let scaledWidth = rawWidth * widthScale * tuning
            let scaledHeight = rawHeight * heightScale * tuning

            let displayBox = DetectionBox(
                x: CGFloat(result.x),
                y: CGFloat(result.y),
                width: scaledWidth,
                height: scaledHeight
            )

            let label = (result.classIndex >= 0 && result.classIndex < classNames.count)
                ? classNames[result.classIndex]
                : "Unknown"

            DispatchQueue.main.async {
                self.detectionBox = displayBox
                self.detectedLabel = label
                self.detectedScore = result.score
                self.status = "Live detection running."
            }

        } catch {
            DispatchQueue.main.async {
                self.status = "Prediction error: \(error.localizedDescription)"
            }
        }
    }

    func findCandidates(in arr: MLMultiArray, threshold: Float = 0.4) -> [DetectionCandidate] {
        let dims = arr.shape.map { Int(truncating: $0) }
        let channels = dims[1]
        let candidates = dims[2]
        let numClasses = channels - 4

        var results: [DetectionCandidate] = []

        for i in 0..<candidates {
            let x = arr[[0, 0 as NSNumber, i as NSNumber]].floatValue
            let y = arr[[0, 1 as NSNumber, i as NSNumber]].floatValue
            let w = arr[[0, 2 as NSNumber, i as NSNumber]].floatValue
            let h = arr[[0, 3 as NSNumber, i as NSNumber]].floatValue

            var bestScore: Float = -.infinity
            var bestClassIndex = -1

            for c in 0..<numClasses {
                let classScore = arr[[0, (4 + c) as NSNumber, i as NSNumber]].floatValue
                if classScore > bestScore {
                    bestScore = classScore
                    bestClassIndex = c
                }
            }

            if bestScore >= threshold {
                results.append(
                    DetectionCandidate(
                        x: x,
                        y: y,
                        w: w,
                        h: h,
                        classIndex: bestClassIndex,
                        score: bestScore
                    )
                )
            }
        }

        return results
    }

    func iou(_ a: DetectionCandidate, _ b: DetectionCandidate) -> Float {
        let aLeft = a.x - a.w / 2
        let aTop = a.y - a.h / 2
        let aRight = a.x + a.w / 2
        let aBottom = a.y + a.h / 2

        let bLeft = b.x - b.w / 2
        let bTop = b.y - b.h / 2
        let bRight = b.x + b.w / 2
        let bBottom = b.y + b.h / 2

        let interLeft = max(aLeft, bLeft)
        let interTop = max(aTop, bTop)
        let interRight = min(aRight, bRight)
        let interBottom = min(aBottom, bBottom)

        let interWidth = max(0, interRight - interLeft)
        let interHeight = max(0, interBottom - interTop)
        let interArea = interWidth * interHeight

        let areaA = a.w * a.h
        let areaB = b.w * b.h
        let unionArea = areaA + areaB - interArea

        guard unionArea > 0 else { return 0 }
        return interArea / unionArea
    }

    func applyNMS(to detections: [DetectionCandidate], iouThreshold: Float = 0.5) -> [DetectionCandidate] {
        let sorted = detections.sorted { $0.score > $1.score }
        var kept: [DetectionCandidate] = []

        for det in sorted {
            var shouldKeep = true

            for keptDet in kept {
                if det.classIndex == keptDet.classIndex && iou(det, keptDet) > iouThreshold {
                    shouldKeep = false
                    break
                }
            }

            if shouldKeep {
                kept.append(det)
            }
        }

        return kept
    }
}
