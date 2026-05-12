//
//  LiveClassificationSummaryView.swift
//  RealWasteClassificator
//
//  Created by Car on 5/8/26.
//

import SwiftUI

struct LiveClassificationSummaryView: View {
    let results: [ClassificationResult]

    var body: some View {
        List {
            Section("Classification Results") {
                if results.isEmpty {
                    Text("No classifications were recorded.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(results) { result in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(result.label)
                                    .font(.headline)

                                Text(result.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text(String(format: "%.2f", result.confidence))
                                .fontWeight(.bold)
                        }
                    }
                }
            }
        }
        .navigationTitle("Capture Summary")
    }
}
