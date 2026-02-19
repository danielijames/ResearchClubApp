//
//  MassiveAPIResponse.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation

/// Response model for Massive API minute aggregates endpoint
struct MassiveAggregatesResponse: Codable {
    let ticker: String?
    let queryCount: Int?
    let resultsCount: Int?
    let adjusted: Bool?
    let status: String?
    let results: [AggregateResult]?
    
    enum CodingKeys: String, CodingKey {
        case ticker = "ticker"
        case queryCount = "queryCount"
        case resultsCount = "resultsCount"
        case adjusted = "adjusted"
        case status = "status"
        case results = "results"
    }
}

/// Individual aggregate result from Massive API
struct AggregateResult: Codable {
    let timestamp: Int64 // Unix millisecond timestamp
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int64
    let volumeWeighted: Double?
    let transactionCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case timestamp = "t"
        case open = "o"
        case high = "h"
        case low = "l"
        case close = "c"
        case volume = "v"
        case volumeWeighted = "vw"
        case transactionCount = "n"
    }
}
