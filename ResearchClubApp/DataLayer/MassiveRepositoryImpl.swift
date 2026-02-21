//
//  MassiveRepositoryImpl.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation

/// Concrete implementation of MassiveRepository for accessing Massive API stock data.
/// Supports both REST API and S3 flat file access methods.
class MassiveRepositoryImpl: MassiveRepository {
    private let apiKey: String
    private let baseURL: String
    private let session: URLSession
    
    /// Initializes the repository with API credentials
    /// - Parameters:
    ///   - apiKey: Your Massive API key
    ///   - baseURL: Base URL for Massive API (default: "https://api.massive.com")
    ///   Note: Massive.com is rebranded Polygon.io. Use "https://api.massive.com" (primary) or "https://api.polygon.io" (legacy)
    init(apiKey: String, baseURL: String = "https://api.massive.com") {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.session = URLSession.shared
        print("🏗️ MassiveRepositoryImpl initialized")
        print("   API key length: \(apiKey.count)")
        print("   API key is empty: \(apiKey.isEmpty)")
        if !apiKey.isEmpty {
            print("   API key prefix: \(apiKey.prefix(8))...")
        }
    }
    
    // MARK: - Aggregates
    
    func getAggregates(
        ticker: String,
        startDate: Date,
        endDate: Date,
        granularity: AggregateGranularity
    ) async throws -> [StockAggregate] {
        // Massive API endpoint: GET /v2/aggs/ticker/{ticker}/range/{multiplier}/{timespan}/{from}/{to}
        
        let tickerUpper = ticker.uppercased()
        
        // Convert dates to milliseconds (Unix timestamp * 1000)
        let fromTimestamp = Int64(startDate.timeIntervalSince1970 * 1000)
        let toTimestamp = Int64(endDate.timeIntervalSince1970 * 1000)
        
        // Build URL using granularity settings
        let multiplier = granularity.multiplier
        let timespan = granularity.timespan
        let urlString = "\(baseURL)/v2/aggs/ticker/\(tickerUpper)/range/\(multiplier)/\(timespan)/\(fromTimestamp)/\(toTimestamp)"
        
        var components = URLComponents(string: urlString)
        components?.queryItems = [
            URLQueryItem(name: "adjusted", value: "true"),
            URLQueryItem(name: "sort", value: "asc"),
            URLQueryItem(name: "limit", value: "50000"), // Max limit
            URLQueryItem(name: "apikey", value: apiKey) // Also include in query string as fallback
        ]
        
        guard let url = components?.url else {
            throw MassiveRepositoryError.invalidURL
        }
        
        // Debug: Print the URL being called (without API key in log)
        var debugURL = url
        if var urlComponents = URLComponents(string: url.absoluteString) {
            urlComponents.queryItems = urlComponents.queryItems?.map { item in
                if item.name == "apikey" {
                    return URLQueryItem(name: "apikey", value: "***")
                }
                return item
            }
            debugURL = urlComponents.url ?? url
        }
        print("🔍 API Request URL: \(debugURL.absoluteString)")
        print("🔑 API Key length: \(apiKey.count)")
        if apiKey.isEmpty {
            print("❌ WARNING: API Key is EMPTY!")
        } else {
            print("🔑 API Key prefix: \(apiKey.prefix(8))...")
        }
        print("🌐 Base URL: \(baseURL)")
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "GET"
        request.timeoutInterval = 30.0
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            print("❌ Network Error: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("   URL Error Code: \(urlError.code.rawValue)")
                print("   URL Error Description: \(urlError.localizedDescription)")
                
                // Provide helpful error message based on error code
                if urlError.code == .cannotFindHost || urlError.code == .dnsLookupFailed {
                    let helpfulMessage = """
                    DNS resolution failed. Possible issues:
                    1. Check your internet connection
                    2. Try using 'https://api.massive.com' instead of 'https://api.polygon.io'
                    3. Check if your network/firewall is blocking the connection
                    4. Verify the API endpoint is correct: \(url.absoluteString)
                    """
                    print(helpfulMessage)
                }
            }
            throw MassiveRepositoryError.networkError(error.localizedDescription)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MassiveRepositoryError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error message from response
            if let errorData = String(data: data, encoding: .utf8) {
                print("API Error Response: \(errorData)")
            }
            throw MassiveRepositoryError.apiError(statusCode: httpResponse.statusCode)
        }
        
        // Parse JSON response
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(MassiveAggregatesResponse.self, from: data)
        
        // Map API response to domain model
        guard let results = apiResponse.results else {
            return []
        }
        
        return results.compactMap { result in
            // Convert millisecond timestamp to Date
            let timestamp = Date(timeIntervalSince1970: TimeInterval(result.timestamp) / 1000.0)
            
            return StockAggregate(
                ticker: tickerUpper,
                timestamp: timestamp,
                open: result.open,
                high: result.high,
                low: result.low,
                close: result.close,
                volume: result.volume,
                granularityMinutes: granularity.rawValue
            )
        }
    }
    
    func getAggregates(
        ticker: String,
        date: Date,
        granularity: AggregateGranularity
    ) async throws -> [StockAggregate] {
        // Get start and end of the day
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw MassiveRepositoryError.invalidDate
        }
        
        // Use the date range method
        return try await getAggregates(
            ticker: ticker,
            startDate: startOfDay,
            endDate: endOfDay,
            granularity: granularity
        )
    }
    
    // MARK: - Quotes
    
    func getQuotes(
        ticker: String,
        startDate: Date,
        endDate: Date,
        limit: Int? = nil
    ) async throws -> [StockQuote] {
        // REST API endpoint: GET /v3/quotes/{ticker}
        // Query parameters: gte, lte, limit, order, sort
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var components = URLComponents(string: "\(baseURL)/v3/quotes/\(ticker.uppercased())")
        components?.queryItems = [
            URLQueryItem(name: "gte", value: dateFormatter.string(from: startDate)),
            URLQueryItem(name: "lte", value: dateFormatter.string(from: endDate)),
            URLQueryItem(name: "limit", value: limit.map { String($0) } ?? "1000"),
            URLQueryItem(name: "order", value: "asc"),
            URLQueryItem(name: "sort", value: "timestamp")
        ]
        
        guard let url = components?.url else {
            throw MassiveRepositoryError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MassiveRepositoryError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw MassiveRepositoryError.apiError(statusCode: httpResponse.statusCode)
        }
        
        // TODO: Parse JSON response and map to StockQuote array
        // Response format depends on Massive API structure
        throw MassiveRepositoryError.notImplemented("Quote parsing not yet implemented")
    }
    
    func getLatestQuote(ticker: String) async throws -> StockQuote? {
        // Get quotes from the last hour
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -1, to: endDate) ?? endDate
        let quotes = try await getQuotes(ticker: ticker, startDate: startDate, endDate: endDate, limit: 1)
        return quotes.first
    }
    
    // MARK: - Ticker Details
    
    func getTickerDetails(ticker: String, date: Date?) async throws -> TickerDetails {
        // Massive API endpoint: GET /v3/reference/tickers/{ticker}
        let tickerUpper = ticker.uppercased()
        var urlString = "\(baseURL)/v3/reference/tickers/\(tickerUpper)"
        
        var components = URLComponents(string: urlString)
        var queryItems: [URLQueryItem] = []
        
        // Add date parameter if provided (for point-in-time queries)
        if let date = date {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate]
            queryItems.append(URLQueryItem(name: "date", value: dateFormatter.string(from: date)))
        }
        
        queryItems.append(URLQueryItem(name: "apikey", value: apiKey))
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw MassiveRepositoryError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "GET"
        request.timeoutInterval = 30.0
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MassiveRepositoryError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw MassiveRepositoryError.apiError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(MassiveTickerDetailsResponse.self, from: data)
        
        guard let result = apiResponse.results else {
            throw MassiveRepositoryError.invalidResponse
        }
        
        return TickerDetails(
            ticker: result.ticker,
            marketCap: result.marketCap,
            shareClassSharesOutstanding: result.shareClassSharesOutstanding,
            weightedSharesOutstanding: result.weightedSharesOutstanding
        )
    }
}

// MARK: - Errors

enum MassiveRepositoryError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidDate
    case apiError(statusCode: Int)
    case notImplemented(String)
    case s3AccessNotConfigured
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for API request"
        case .invalidResponse:
            return "Invalid response from API"
        case .invalidDate:
            return "Invalid date range"
        case .apiError(let statusCode):
            return "API error with status code: \(statusCode)"
        case .notImplemented(let message):
            return "Not implemented: \(message)"
        case .s3AccessNotConfigured:
            return "S3 access is not configured. Please set up AWS credentials."
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
