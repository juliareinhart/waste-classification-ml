import SwiftUI

struct ContentView: View {
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

                    Text("Real Waste Classificator")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)

                    Spacer()

                    NavigationLink {
                        LiveClassificationView()
                    } label: {
                        Text("Use Camera Live Classification")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)

                    NavigationLink {
                        PhotoAnalyzeView()
                    } label: {
                        Text("Take Picture and Analyze")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)

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

struct LiveClassificationView: View {
    @StateObject private var camera = CameraManager()
    
    @State private var showSummary = false

    var body: some View {
        ZStack {
            CameraPreview(session: camera.session)
                .ignoresSafeArea()
                .navigationDestination(isPresented: $showSummary) {
                    LiveClassificationSummaryView(results: camera.resultsLog)
                }

            VStack {
                Spacer()

                HStack {
                    Spacer()

                    VStack(spacing: 10) {
                        if !camera.currentLabel.isEmpty {
                            Text("\(camera.currentLabel) \(String(format: "%.2f", camera.currentConfidence))")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }

                        Button("Stop") {
                            camera.stop()
                            showSummary = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()

                    Spacer()
                }
            }
        }
        .navigationTitle("Live Classification")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            camera.start()
        }
        
        /*VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("Classification Log")
                    .font(.headline)

                ForEach(camera.resultsLog.suffix(5)) { result in
                    HStack {
                        Text(result.label)
                            .fontWeight(.semibold)

                        Spacer()

                        Text(String(format: "%.2f", result.confidence))
                    }
                    .font(.caption)
                }
            }
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()
        }*/
        .onDisappear {
            camera.stop()
        }
    }
}

struct PhotoAnalyzePlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Take Picture and Analyze")
                .font(.title)

            Text("Photo analysis feature will be added later.")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
