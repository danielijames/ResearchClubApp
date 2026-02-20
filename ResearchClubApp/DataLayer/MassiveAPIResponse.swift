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

/// Response model for Massive API ticker details endpoint (GET /v3/reference/tickers/{ticker})
struct MassiveTickerDetailsResponse: Codable {
    let results: TickerDetailsResult?
    
    enum CodingKeys: String, CodingKey {
        case results = "results"
    }
}

/// Ticker details result from Massive API
struct TickerDetailsResult: Codable {
    let ticker: String
    let name: String?
    let description: String?
    let marketCap: Double?
    let shareClassSharesOutstanding: Int64?
    let weightedSharesOutstanding: Int64?
    let primaryExchange: String?
    let currencyName: String?
    let currencySymbol: String?
    let sicCode: String?
    let sicDescription: String?
    let homepageUrl: String?
    let phoneNumber: String?
    let address: Address?
    let listDate: String? // ISO 8601 date string
    let delistedUtc: String? // ISO 8601 date string
    let active: Bool?
    
    enum CodingKeys: String, CodingKey {
        case ticker
        case name
        case description
        case marketCap = "market_cap"
        case shareClassSharesOutstanding = "share_class_shares_outstanding"
        case weightedSharesOutstanding = "weighted_shares_outstanding"
        case primaryExchange = "primary_exchange"
        case currencyName = "currency_name"
        case currencySymbol = "currency_symbol"
        case sicCode = "sic_code"
        case sicDescription = "sic_description"
        case homepageUrl = "homepage_url"
        case phoneNumber = "phone_number"
        case address
        case listDate = "list_date"
        case delistedUtc = "delisted_utc"
        case active
    }
}

/// Address information from Massive API
struct Address: Codable {
    let address1: String?
    let city: String?
    let state: String?
    let postalCode: String?
    let country: String?
    
    enum CodingKeys: String, CodingKey {
        case address1
        case city
        case state
        case postalCode = "postal_code"
        case country
    }
}
