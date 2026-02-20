//
//  MockMassiveRepository.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation

/// Mock implementation of MassiveRepository for testing and development.
/// Returns sample data without making actual API calls.
class MockMassiveRepository: MassiveRepository {
    func getAggregates(
        ticker: String,
        startDate: Date,
        endDate: Date,
        granularity: AggregateGranularity
    ) async throws -> [StockAggregate] {
        // Return mock data for testing
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: startDate)
        return try await getAggregates(ticker: ticker, date: startOfDay, granularity: granularity)
    }
    
    func getAggregates(
        ticker: String,
        date: Date,
        granularity: AggregateGranularity
    ) async throws -> [StockAggregate] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Generate mock aggregates for the day based on granularity
        var aggregates: [StockAggregate] = []
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Market hours: 9:30 AM to 4:00 PM ET = 390 minutes
        let marketMinutes = 390
        let granularityMinutes = granularity.rawValue
        let numberOfBars = marketMinutes / granularityMinutes
        
        let basePrice = Double.random(in: 100...200)
        
        for barIndex in 0..<numberOfBars {
            let minuteOffset = barIndex * granularityMinutes + 30 // Start at 9:30 AM
            guard let timestamp = calendar.date(byAdding: .minute, value: minuteOffset, to: startOfDay) else {
                continue
            }
            
            // Generate realistic OHLCV data
            let priceVariation = Double.random(in: -2...2)
            let open = basePrice + priceVariation
            let high = open + Double.random(in: 0...1.5)
            let low = open - Double.random(in: 0...1.5)
            let close = Double.random(in: min(low, open)...max(high, open))
            let volume = Int64.random(in: 1000...100000) * Int64(granularityMinutes) // Scale volume by granularity
            
            let aggregate = StockAggregate(
                ticker: ticker.uppercased(),
                timestamp: timestamp,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume,
                granularityMinutes: granularityMinutes
            )
            aggregates.append(aggregate)
        }
        
        return aggregates
    }
    
    func getQuotes(
        ticker: String,
        startDate: Date,
        endDate: Date,
        limit: Int?
    ) async throws -> [StockQuote] {
        // Mock implementation
        return []
    }
    
    func getLatestQuote(ticker: String) async throws -> StockQuote? {
        // Mock implementation
        return nil
    }
    
    func getTickerDetails(ticker: String, date: Date?) async throws -> TickerDetails {
        // Mock implementation - return sample data
        return TickerDetails(
            ticker: ticker.uppercased(),
            marketCap: 1_500_000_000_000, // $1.5T
            shareClassSharesOutstanding: 15_000_000_000, // 15B shares
            weightedSharesOutstanding: 15_000_000_000
        )
    }
}
