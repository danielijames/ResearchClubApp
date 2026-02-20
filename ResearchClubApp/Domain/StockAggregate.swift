//
//  StockAggregate.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation

/// Represents time-based candlestick data for a stock
/// Contains OHLCV (Open, High, Low, Close, Volume) data for a specific time period
struct StockAggregate: Identifiable, Codable, Equatable {
    let id: String // Unique identifier combining ticker and timestamp
    let ticker: String // Stock ticker symbol (e.g., "AAPL")
    let timestamp: Date // The timestamp for this aggregate period
    let open: Double // Opening price
    let high: Double // Highest price
    let low: Double // Lowest price
    let close: Double // Closing price
    let volume: Int64 // Trading volume
    let granularityMinutes: Int // Number of minutes this aggregate represents
    
    init(ticker: String, timestamp: Date, open: Double, high: Double, low: Double, close: Double, volume: Int64, granularityMinutes: Int = 1) {
        self.ticker = ticker
        self.timestamp = timestamp
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
        self.granularityMinutes = granularityMinutes
        self.id = "\(ticker)_\(Int(timestamp.timeIntervalSince1970))_\(granularityMinutes)"
    }
}

/// Granularity options for stock aggregates
enum AggregateGranularity: Int, CaseIterable, Identifiable, Equatable {
    case oneMinute = 1
    case fiveMinutes = 5
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    case oneHour = 60
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .oneMinute:
            return "1 minute"
        case .fiveMinutes:
            return "5 minutes"
        case .fifteenMinutes:
            return "15 minutes"
        case .thirtyMinutes:
            return "30 minutes"
        case .oneHour:
            return "1 hour"
        }
    }
    
    var timespan: String {
        // For Massive API: "minute" for minute-based, "hour" for hour-based
        if rawValue >= 60 {
            return "hour"
        }
        return "minute"
    }
    
    var multiplier: Int {
        // For hour-based, convert to hours
        if rawValue >= 60 {
            return rawValue / 60
        }
        return rawValue
    }
}
