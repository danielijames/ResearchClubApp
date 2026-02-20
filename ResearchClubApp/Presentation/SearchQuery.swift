//
//  SearchQuery.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation

struct SearchQuery: Identifiable, Equatable {
    let id: UUID
    let ticker: String
    let date: Date
    let granularity: AggregateGranularity
    let aggregates: [StockAggregate]
    let timestamp: Date // When the search was performed
    
    init(
        id: UUID = UUID(),
        ticker: String,
        date: Date,
        granularity: AggregateGranularity,
        aggregates: [StockAggregate],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.ticker = ticker
        self.date = date
        self.granularity = granularity
        self.aggregates = aggregates
        self.timestamp = timestamp
    }
    
    var displayName: String {
        "\(ticker.uppercased()) - \(formatDate(date)) - \(granularity.displayName)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
