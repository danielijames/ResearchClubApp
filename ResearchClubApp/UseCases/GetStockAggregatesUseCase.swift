//
//  GetStockAggregatesUseCase.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation

/// Use case for fetching stock aggregates with configurable granularity.
/// Encapsulates the business logic for retrieving stock data.
struct GetStockAggregatesUseCase {
    private let repository: any MassiveRepository
    
    init(repository: any MassiveRepository) {
        self.repository = repository
    }
    
    /// Executes the use case to fetch aggregates for a specific ticker and date
    /// - Parameters:
    ///   - ticker: Stock ticker symbol (will be normalized to uppercase)
    ///   - date: The date to fetch data for
    ///   - granularity: The time granularity for aggregates (default: 5 minutes)
    /// - Returns: Array of aggregates, sorted by timestamp
    /// - Throws: Repository errors or validation errors
    func execute(ticker: String, date: Date, granularity: AggregateGranularity = .fiveMinutes) async throws -> [StockAggregate] {
        // Business logic: Validate ticker
        let normalizedTicker = ticker.trimmingCharacters(in: .whitespaces).uppercased()
        guard !normalizedTicker.isEmpty else {
            throw UseCaseError.invalidTicker("Ticker cannot be empty")
        }
        
        // Business logic: Validate date (should not be in the future)
        let today = Calendar.current.startOfDay(for: Date())
        let selectedDate = Calendar.current.startOfDay(for: date)
        if selectedDate > today {
            throw UseCaseError.invalidDate("Cannot fetch data for future dates")
        }
        
        // Fetch data from repository
        let aggregates = try await repository.getAggregates(
            ticker: normalizedTicker,
            date: date,
            granularity: granularity
        )
        
        // Business logic: Sort by timestamp (earliest first)
        return aggregates.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// Executes the use case to fetch aggregates for a date range
    /// - Parameters:
    ///   - ticker: Stock ticker symbol (will be normalized to uppercase)
    ///   - startDate: Start date for the range
    ///   - endDate: End date for the range
    ///   - granularity: The time granularity for aggregates (default: 5 minutes)
    /// - Returns: Array of aggregates, sorted by timestamp
    /// - Throws: Repository errors or validation errors
    func execute(ticker: String, startDate: Date, endDate: Date, granularity: AggregateGranularity = .fiveMinutes) async throws -> [StockAggregate] {
        // Business logic: Validate ticker
        let normalizedTicker = ticker.trimmingCharacters(in: .whitespaces).uppercased()
        guard !normalizedTicker.isEmpty else {
            throw UseCaseError.invalidTicker("Ticker cannot be empty")
        }
        
        // Business logic: Validate date range
        guard startDate <= endDate else {
            throw UseCaseError.invalidDate("Start date must be before or equal to end date")
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let selectedStartDate = Calendar.current.startOfDay(for: startDate)
        if selectedStartDate > today {
            throw UseCaseError.invalidDate("Cannot fetch data for future dates")
        }
        
        // Fetch data from repository
        let aggregates = try await repository.getAggregates(
            ticker: normalizedTicker,
            startDate: startDate,
            endDate: endDate,
            granularity: granularity
        )
        
        // Business logic: Sort by timestamp (earliest first)
        return aggregates.sorted { $0.timestamp < $1.timestamp }
    }
}

// MARK: - Errors

enum UseCaseError: LocalizedError {
    case invalidTicker(String)
    case invalidDate(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidTicker(let message):
            return "Invalid ticker: \(message)"
        case .invalidDate(let message):
            return "Invalid date: \(message)"
        }
    }
}
