//
//  ClassificationResult.swift
//  RealWasteClassificator
//
//  Created by Car on 5/8/26.
//

import Foundation

struct ClassificationResult: Identifiable {
    let id = UUID()
    let label: String
    let confidence: Double
    let timestamp: Date
}
