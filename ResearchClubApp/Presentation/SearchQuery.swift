//
//  SearchQuery.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation

struct SearchQuery: Identifiable, Equatable, Codable {
    let id: UUID
    let ticker: String
    let date: Date
    let granularity: AggregateGranularity
    let aggregates: [StockAggregate]
    let tickerDetails: TickerDetails?
    let timestamp: Date // When the search was performed
    
    init(
        id: UUID = UUID(),
        ticker: String,
        date: Date,
        granularity: AggregateGranularity,
        aggregates: [StockAggregate],
        tickerDetails: TickerDetails? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.ticker = ticker
        self.date = date
        self.granularity = granularity
        self.aggregates = aggregates
        self.tickerDetails = tickerDetails
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
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, ticker, date, granularity, aggregates, tickerDetails, timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        ticker = try container.decode(String.self, forKey: .ticker)
        date = try container.decode(Date.self, forKey: .date)
        let granularityValue = try container.decode(Int.self, forKey: .granularity)
        granularity = AggregateGranularity(rawValue: granularityValue) ?? .fiveMinutes
        aggregates = try container.decode([StockAggregate].self, forKey: .aggregates)
        tickerDetails = try container.decodeIfPresent(TickerDetails.self, forKey: .tickerDetails)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(ticker, forKey: .ticker)
        try container.encode(date, forKey: .date)
        try container.encode(granularity.rawValue, forKey: .granularity)
        try container.encode(aggregates, forKey: .aggregates)
        try container.encodeIfPresent(tickerDetails, forKey: .tickerDetails)
        try container.encode(timestamp, forKey: .timestamp)
    }
}
