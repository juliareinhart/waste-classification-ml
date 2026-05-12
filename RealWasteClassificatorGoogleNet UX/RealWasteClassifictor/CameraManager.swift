//
//  CameraManager.swift
//  RealWasteClassificator
//
//  Created by Car on 5/8/26.
//
import Foundation
import AVFoundation
import CoreML
import CoreImage
import Combine

final class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()

    @Published var statusMessage: String = "Camera not started"
    @Published var currentLabel: String = ""
    @Published var currentConfidence: Double = 0.0
    
    @Published var resultsLog: [ClassificationResult] = []
    
    private var lastLoggedLabel: String = ""

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoQueue = DispatchQueue(label: "camera.video.queue")
    private let ciContext = CIContext()

    private var isProcessingFrame = false
    private var frameCounter = 0

    private let model: GoogLeNet? = {
        do {
            return try GoogLeNet(configuration: MLModelConfiguration())
        } catch {
            print("Model load error:", error)
            return nil
        }
    }()

    func start() {
        checkPermissionAndStart()
    }

    func stop() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    private func checkPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.configureSession()
                } else {
                    DispatchQueue.main.async {
                        self.statusMessage = "Camera permission denied"
                    }
                }
            }

        default:
            DispatchQueue.main.async {
                self.statusMessage = "Camera permission denied"
            }
        }
    }

    private func configureSession() {
        sessionQueue.async {
            guard self.session.inputs.isEmpty else {
                if !self.session.isRunning {
                    self.session.startRunning()
                }
                DispatchQueue.main.async {
                    self.statusMessage = "Camera running"
                }
                return
            }

            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                       for: .video,
                                                       position: .back) else {
                DispatchQueue.main.async {
                    self.statusMessage = "Back camera not found"
                }
                self.session.commitConfiguration()
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: camera)

                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                } else {
                    DispatchQueue.main.async {
                        self.statusMessage = "Could not add camera input"
                    }
                    self.session.commitConfiguration()
                    return
                }

                let output = AVCaptureVideoDataOutput()
                output.alwaysDiscardsLateVideoFrames = true
                output.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                output.setSampleBufferDelegate(self, queue: self.videoQueue)

                if self.session.canAddOutput(output) {
                    self.session.addOutput(output)
                } else {
                    DispatchQueue.main.async {
                        self.statusMessage = "Could not add video output"
                    }
                    self.session.commitConfiguration()
                    return
                }

                self.session.commitConfiguration()
                self.session.startRunning()

                DispatchQueue.main.async {
                    self.statusMessage = "Camera running"
                }

            } catch {
                DispatchQueue.main.async {
                    self.statusMessage = "Camera error: \(error.localizedDescription)"
                }
                self.session.commitConfiguration()
            }
        }
    }
    
    private func updateLog(label: String, confidence: Double) {
        if label != lastLoggedLabel {
            lastLoggedLabel = label

            let result = ClassificationResult(
                label: label,
                confidence: confidence,
                timestamp: Date()
            )

            DispatchQueue.main.async {
                self.resultsLog.append(result)
            }
        }
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        frameCounter += 1

        // Process every 5th frame to keep the app responsive
        if frameCounter % 5 != 0 {
            return
        }

        guard !isProcessingFrame else { return }
        guard let model else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        isProcessingFrame = true
        defer { isProcessingFrame = false }

        guard let resizedBuffer = resizePixelBuffer(pixelBuffer, width: 224, height: 224) else {
            DispatchQueue.main.async {
                self.statusMessage = "Failed to resize frame"
            }
            return
        }

        do {
            let output = try model.prediction(input: resizedBuffer)

            let label = output.classLabel
            let confidence = output.classLabel_probs[label] ?? 0.0
            
            updateLog(label: label, confidence: confidence)

            DispatchQueue.main.async {
                self.currentLabel = label
                self.currentConfidence = confidence
                self.statusMessage = "Classifying live camera"
            }

        } catch {
            DispatchQueue.main.async {
                self.statusMessage = "Prediction error: \(error.localizedDescription)"
            }
        }
    }

    private func resizePixelBuffer(_ pixelBuffer: CVPixelBuffer,
                                   width: Int,
                                   height: Int) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        let scaleX = CGFloat(width) / CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let scaleY = CGFloat(height) / CGFloat(CVPixelBufferGetHeight(pixelBuffer))

        let resizedImage = ciImage.transformed(
            by: CGAffineTransform(scaleX: scaleX, y: scaleY)
        )

        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA
        ]

        var outputBuffer: CVPixelBuffer?

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &outputBuffer
        )

        guard status == kCVReturnSuccess, let outputBuffer else {
            return nil
        }

        ciContext.render(resizedImage, to: outputBuffer)
        return outputBuffer
    }
}
