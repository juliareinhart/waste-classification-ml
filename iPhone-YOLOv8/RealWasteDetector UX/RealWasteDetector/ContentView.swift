import SwiftUI

struct DetectionBox {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
}

struct DetectionCandidate {
    let x: Float
    let y: Float
    let w: Float
    let h: Float
    let classIndex: Int
    let score: Float
}

struct ContentView: View {
    @StateObject private var camera = CameraManager()
    
    // To use stats
    @StateObject private var stats = DetectionStats()
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            CameraPreview(session: camera.session)
                .ignoresSafeArea()

            GeometryReader { geometry in
                let size = geometry.size

                if let box = camera.detectionBox {
                    let mapped = convertToDisplayBox(
                        centerX: box.x,
                        centerY: box.y,
                        width: box.width,
                        height: box.height,
                        imageSize: CGSize(width: 640, height: 640),
                        containerSize: size
                    )

                    Rectangle()
                        .stroke(Color.red, lineWidth: 3)
                        .frame(width: mapped.width, height: mapped.height)
                        .position(
                            x: mapped.x + mapped.width / 2,
                            y: mapped.y + mapped.height / 2
                        )

                    if !camera.detectedLabel.isEmpty {
                        Text("\(camera.detectedLabel) \(String(format: "%.2f", camera.detectedScore))")
                            .font(.caption)
                            .padding(6)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .position(
                                x: mapped.x + 80,
                                y: max(16, mapped.y - 10)
                            )
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("RealWaste Live")
                    .font(.headline)
                    .padding(.top, 16)

                Text(camera.status)
                    .font(.caption)
            }
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()
            
            // Add for stats
            VStack {
                Spacer()
                
                NavigationLink {
                    LiveStatsView(stats: stats)
                } label: {
                    Text("Stop & Show Stats")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            stats.reset()   // <-- Reset stats
            camera.start()
            camera.onDetection = { label, score in
                stats.add(label: label, confidence: score)
            }
        }
        .onDisappear {
            camera.stop()
        }
    }

    func aspectFitRect(imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height

        if imageAspect > containerAspect {
            let width = containerSize.width
            let height = width / imageAspect
            let y = (containerSize.height - height) / 2
            return CGRect(x: 0, y: y, width: width, height: height)
        } else {
            let height = containerSize.height
            let width = height * imageAspect
            let x = (containerSize.width - width) / 2
            return CGRect(x: x, y: 0, width: width, height: height)
        }
    }

    func convertToDisplayBox(
        centerX: CGFloat,
        centerY: CGFloat,
        width: CGFloat,
        height: CGFloat,
        imageSize: CGSize,
        containerSize: CGSize
    ) -> DetectionBox {
        let imageFrame = aspectFitRect(imageSize: imageSize, in: containerSize)

        let scaleX = imageFrame.width / imageSize.width
        let scaleY = imageFrame.height / imageSize.height

        let boxWidth = width * scaleX
        let boxHeight = height * scaleY
        let left = imageFrame.minX + (centerX - width / 2) * scaleX
        let top = imageFrame.minY + (centerY - height / 2) * scaleY

        return DetectionBox(
            x: left,
            y: top,
            width: max(1, boxWidth),
            height: max(1, boxHeight)
        )
    }
}
