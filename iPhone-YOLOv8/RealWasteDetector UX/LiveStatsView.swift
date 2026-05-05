//
//  LiveStatsView.swift
//  RealWasteDetector
//
//  Created by Car on 5/3/26.
//

import SwiftUI

struct LiveStatsView: View {
    @ObservedObject var stats: DetectionStats

    var body: some View {
        List {
            Section(header: Text("Detection Summary")) {
                ForEach(stats.summary(), id: \.label) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.label)
                            .font(.headline)

                        Text("Objects detected: \(item.count)")

                        Text("Average score: \(item.averageConfidence * 100, specifier: "%.1f")%")
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Live Stats")
    }
}
