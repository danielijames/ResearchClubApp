//
//  AppState.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation

/// Represents the complete application state that should be persisted
struct AppState: Codable {
    var selectedTabId: UUID?
    var tabs: [ResearchTab]
    var cohorts: [Cohort] // All cohorts across the app
    var inputState: InputState
    var geminiChatWidth: CGFloat
    var isSidebarCollapsed: Bool
    var lastSavedAt: Date
    
    init(
        selectedTabId: UUID? = nil,
        tabs: [ResearchTab] = [
            ResearchTab(id: ResearchTab.searchHistoryTabId, name: "Search History", isSearchHistoryTab: true),
            ResearchTab(name: "Research 1", showGeminiChat: false)
        ],
        cohorts: [Cohort] = [],
        inputState: InputState = InputState(),
        geminiChatWidth: CGFloat = 0,
        isSidebarCollapsed: Bool = false,
        lastSavedAt: Date = Date()
    ) {
        self.selectedTabId = selectedTabId
        self.tabs = tabs
        self.cohorts = cohorts
        self.inputState = inputState
        self.geminiChatWidth = geminiChatWidth
        self.isSidebarCollapsed = isSidebarCollapsed
        self.lastSavedAt = lastSavedAt
    }
}

/// Represents the state of input fields
struct InputState: Codable {
    var ticker: String
    var startDate: Date
    var endDate: Date
    var granularityRawValue: Int // Store as Int since AggregateGranularity is an enum
    
    init(
        ticker: String = "",
        startDate: Date? = nil,
        endDate: Date? = nil,
        granularityRawValue: Int = 5 // Default to 5 minutes
    ) {
        self.ticker = ticker
        
        // Default dates to previous day
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        
        if let startDate = startDate {
            self.startDate = startDate
        } else {
            var components = calendar.dateComponents([.year, .month, .day], from: yesterday)
            components.hour = 4
            components.minute = 0
            self.startDate = calendar.date(from: components) ?? yesterday
        }
        
        if let endDate = endDate {
            self.endDate = endDate
        } else {
            var components = calendar.dateComponents([.year, .month, .day], from: yesterday)
            components.hour = 20
            components.minute = 0
            self.endDate = calendar.date(from: components) ?? yesterday
        }
        
        self.granularityRawValue = granularityRawValue
    }
    
    var granularity: AggregateGranularity {
        get {
            AggregateGranularity(rawValue: granularityRawValue) ?? .fiveMinutes
        }
        set {
            granularityRawValue = newValue.rawValue
        }
    }
}
