//
//  PhotoCaptureView.swift
//  RealWasteDetector
//
//  Created by Car on 5/3/26.
//

import SwiftUI

struct PhotoCaptureView: View {
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var showResult = false

    @StateObject private var camera = CameraManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Photo Waste Detection")
                .font(.title)
                .fontWeight(.bold)

            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 420)
                    .cornerRadius(12)
            } else {
                Text("Take a picture to analyze waste type.")
                    .multilineTextAlignment(.center)
                    .padding()
            }

            Button("Take Picture") {
                showCamera = true
            }
            .buttonStyle(.borderedProminent)

            Button("Analyze Photo") {
                showResult = true
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
        .navigationTitle("Photo Mode")
        .sheet(isPresented: $showCamera) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .navigationDestination(isPresented: $showResult) {
            if let image = selectedImage {
                let results = camera.detectPhoto(image: image)
                PhotoResultView(image: image, detectionResults: results)
            } else {
                Text("Take a picture first.")
            }
        }
    }
}

