//
//  PhotoAnalyzeView.swift
//  RealWasteClassificator
//
//  Created by Car on 5/8/26.
//

import SwiftUI
import CoreML

struct PhotoAnalyzeView: View {
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    
    @State private var resultLabel: String = ""
    @State private var resultConfidence: Double = 0.0

    var body: some View {
        VStack(spacing: 20) {
            Text("Take Picture and Analyze")
                .font(.title)
                .fontWeight(.bold)

            if let capturedImage {
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 350)
            } else {
                Text("No picture captured yet.")
                    .foregroundColor(.secondary)
            }

            if !resultLabel.isEmpty {
                VStack(spacing: 8) {
                    Text(resultLabel)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.red)

                    Text("Confidence: \(String(format: "%.2f", resultConfidence))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Button("Take Picture") {
                showCamera = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding()
        .navigationTitle("Photo Analysis")
        .sheet(isPresented: $showCamera) {
            PhotoCaptureController { image in
                capturedImage = image
                classifyImage(image)
            }
        }
    }
    
    private func classifyImage(_ image: UIImage) {
        guard let pixelBuffer = image.toPixelBuffer(width: 224, height: 224) else {
            return
        }

        do {
            let model = try GoogLeNet(configuration: MLModelConfiguration())
            let output = try model.prediction(input: pixelBuffer)

            let label = output.classLabel
            let confidence = output.classLabel_probs[label] ?? 0.0

            resultLabel = label
            resultConfidence = confidence

        } catch {
            print("Prediction error:", error)
        }
    }
}

extension UIImage {
    func toPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attrs,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            CVPixelBufferUnlockBaseAddress(buffer, [])
            return nil
        }

        guard let cgImage = self.cgImage else {
            CVPixelBufferUnlockBaseAddress(buffer, [])
            return nil
        }

        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
}
