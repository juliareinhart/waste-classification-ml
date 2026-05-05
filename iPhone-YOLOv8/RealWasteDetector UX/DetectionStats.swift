//
//  DetectionStats.swift
//  RealWasteDetector
//
//  Created by Car on 5/3/26.
//

import Foundation
import Combine

struct WasteDetection {
    let label: String
    let confidence: Double
}

class DetectionStats: ObservableObject {
    @Published var detections: [WasteDetection] = []

    func add(label: String, confidence: Double) {
        detections.append(
            WasteDetection(label: label, confidence: confidence)
        )
    }

    func summary() -> [(label: String, count: Int, averageConfidence: Double)] {
        let grouped = Dictionary(grouping: detections, by: { $0.label })

        return grouped.map { label, items in
            let average = items.map { $0.confidence }.reduce(0, +) / Double(items.count)
            return (
                label: label,
                count: items.count,
                averageConfidence: average
            )
        }
        .sorted { $0.label < $1.label }
    }

    func reset() {
        detections.removeAll()
    }
}
