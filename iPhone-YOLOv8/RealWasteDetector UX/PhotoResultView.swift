//
//  PhotoResultView.swift
//  RealWasteDetector
//
//  Created by Car on 5/3/26.
//

import SwiftUI

struct PhotoDetectionResult: Identifiable {
    let id = UUID()
    let label: String
    let score: Double
    let rect: CGRect
}

struct PhotoResultView: View {
    let image: UIImage
    let detectionResults: [PhotoDetectionResult]

    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 360, height: 520)

            ForEach(detectionResults) { detection in
                Rectangle()
                    .stroke(Color.red, lineWidth: 3)
                    .frame(width: detection.rect.width, height: detection.rect.height)
                    .position(x: detection.rect.midX, y: detection.rect.midY)

                Text("\(detection.label) \(detection.score * 100, specifier: "%.1f")%")
                    .font(.caption)
                    .padding(5)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .position(x: detection.rect.midX, y: detection.rect.minY - 12)
            }
        }
        .frame(width: 360, height: 520)
        .navigationTitle("Prediction Result")
        
        /*ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 360, height: 520)

            // 🔴 FORCE TEST BOX
            Rectangle()
                .stroke(Color.red, lineWidth: 5)
                .frame(width: 200, height: 200)
                .position(x: 180, y: 260)

            Text("TEST 90%")
                .font(.caption)
                .padding(5)
                .background(Color.red)
                .foregroundColor(.white)
                .position(x: 180, y: 140)
        }
        .frame(width: 360, height: 520)
        .navigationTitle("Prediction Result")*/
    }
}
