//
//  WelcomeView.swift
//  RealWasteDetector
//
//  Created by Car on 5/3/26.
//

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.white, .red.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    Text("Real Waste Detector")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)

                    Spacer()

                    NavigationLink {
                        ContentView()
                    } label: {
                        Text("Use Camera Live Detection")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    NavigationLink {
                        PhotoCaptureView()
                    } label: {
                        Text("Take Picture and Analyze")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Text("You can now close this app using the iPhone app switcher.")
                        .font(.footnote)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)

                    Spacer()

                    Text("For Academic Purposes")
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 32)
            }
        }
    }
}
