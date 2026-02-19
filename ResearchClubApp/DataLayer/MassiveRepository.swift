//
//  MassiveRepository.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation

/// Repository for accessing stock data from Massive API.
/// Provides methods to fetch aggregates and quotes for stocks.
/// Follows Clean Architecture principles by abstracting data access details.
protocol MassiveRepository {
    /// Fetches aggregates (OHLCV) for a specific stock ticker with specified granularity
    /// - Parameters:
    ///   - ticker: Stock ticker symbol (e.g., "AAPL")
    ///   - startDate: Start date/time for the data range
    ///   - endDate: End date/time for the data range
    ///   - granularity: The time granularity for aggregates (e.g., 1, 5, 15 minutes)
    /// - Returns: Array of aggregates for the specified ticker and date range
    func getAggregates(
        ticker: String,
        startDate: Date,
        endDate: Date,
        granularity: AggregateGranularity
    ) async throws -> [StockAggregate]
    
    /// Fetches aggregates for a specific date with specified granularity
    /// - Parameters:
    ///   - ticker: Stock ticker symbol
    ///   - date: The date to fetch data for
    ///   - granularity: The time granularity for aggregates (e.g., 1, 5, 15 minutes)
    /// - Returns: Array of aggregates for the specified ticker and date
    func getAggregates(
        ticker: String,
        date: Date,
        granularity: AggregateGranularity
    ) async throws -> [StockAggregate]
    
    /// Fetches quotes (NBBO) for a specific stock ticker
    /// - Parameters:
    ///   - ticker: Stock ticker symbol
    ///   - startDate: Start timestamp for the quote data
    ///   - endDate: End timestamp for the quote data
    ///   - limit: Maximum number of quotes to return (default: 1000, max: 50000)
    /// - Returns: Array of quotes for the specified ticker and time range
    func getQuotes(
        ticker: String,
        startDate: Date,
        endDate: Date,
        limit: Int?
    ) async throws -> [StockQuote]
    
    /// Fetches the latest quote for a stock ticker
    /// - Parameter ticker: Stock ticker symbol
    /// - Returns: The most recent quote, or nil if not available
    func getLatestQuote(ticker: String) async throws -> StockQuote?
}
