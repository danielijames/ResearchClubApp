//
//  TickerDetails.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation

/// Domain model for stock ticker financial details
struct TickerDetails: Identifiable, Equatable, Codable {
    let id: UUID
    let ticker: String
    let marketCap: Double? // Market capitalization
    let shareClassSharesOutstanding: Int64? // Float / Shares outstanding
    let weightedSharesOutstanding: Int64? // Weighted shares outstanding
    
    init(
        id: UUID = UUID(),
        ticker: String,
        marketCap: Double? = nil,
        shareClassSharesOutstanding: Int64? = nil,
        weightedSharesOutstanding: Int64? = nil
    ) {
        self.id = id
        self.ticker = ticker
        self.marketCap = marketCap
        self.shareClassSharesOutstanding = shareClassSharesOutstanding
        self.weightedSharesOutstanding = weightedSharesOutstanding
    }
    
    /// Formatted market cap string (e.g., "$2.5T", "$500B", "$1.2M")
    var formattedMarketCap: String? {
        guard let marketCap = marketCap else { return nil }
        return formatLargeNumber(marketCap)
    }
    
    /// Formatted shares outstanding string (e.g., "15.7B shares")
    var formattedSharesOutstanding: String? {
        guard let shares = shareClassSharesOutstanding else { return nil }
        return formatLargeNumber(Double(shares), includeDollarSign: false) + " shares"
    }
    
    /// Formatted weighted shares outstanding string
    var formattedWeightedSharesOutstanding: String? {
        guard let shares = weightedSharesOutstanding else { return nil }
        return formatLargeNumber(Double(shares), includeDollarSign: false) + " shares"
    }
    
    private func formatLargeNumber(_ number: Double, includeDollarSign: Bool = true) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        
        let prefix = includeDollarSign ? "$" : ""
        
        if number >= 1_000_000_000_000 {
            return "\(prefix)\(formatter.string(from: NSNumber(value: number / 1_000_000_000_000)) ?? "")T"
        } else if number >= 1_000_000_000 {
            return "\(prefix)\(formatter.string(from: NSNumber(value: number / 1_000_000_000)) ?? "")B"
        } else if number >= 1_000_000 {
            return "\(prefix)\(formatter.string(from: NSNumber(value: number / 1_000_000)) ?? "")M"
        } else if number >= 1_000 {
            return "\(prefix)\(formatter.string(from: NSNumber(value: number / 1_000)) ?? "")K"
        } else {
            return "\(prefix)\(formatter.string(from: NSNumber(value: number)) ?? "")"
        }
    }
}
