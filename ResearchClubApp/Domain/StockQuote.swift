//
//  StockQuote.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation

/// Represents National Best Bid and Offer (NBBO) quote data for a stock
struct StockQuote: Identifiable, Codable {
    let id: String // Unique identifier combining ticker and timestamp
    let ticker: String // Stock ticker symbol
    let timestamp: Date // Quote timestamp (nanosecond precision)
    let bidPrice: Double // Best bid price
    let bidSize: Int // Best bid size
    let askPrice: Double // Best ask price
    let askSize: Int // Best ask size
    let exchange: String? // Exchange identifier
    
    init(ticker: String, timestamp: Date, bidPrice: Double, bidSize: Int, askPrice: Double, askSize: Int, exchange: String? = nil) {
        self.ticker = ticker
        self.timestamp = timestamp
        self.bidPrice = bidPrice
        self.bidSize = bidSize
        self.askPrice = askPrice
        self.askSize = askSize
        self.exchange = exchange
        self.id = "\(ticker)_\(Int(timestamp.timeIntervalSince1970 * 1_000_000_000))"
    }
}
