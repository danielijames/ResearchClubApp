//
//  ResearchTab.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation

struct ResearchTab: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var searchQueries: [SearchQuery]
    var selectedQuery: SearchQuery?
    var showGeminiChat: Bool
    var selectedSpreadsheetForText: SavedSpreadsheet?
    var isSearchHistoryTab: Bool
    var geminiMessages: [ChatMessage]
    var selectedSpreadsheetIds: Set<UUID>
    var spreadsheets: [SavedSpreadsheet] // Spreadsheets assigned to this tab
    var cohortIds: Set<UUID> // Cohorts assigned to this tab
    var selectedCohortIds: Set<UUID> // Cohorts selected for Gemini analysis
    
    init(id: UUID = UUID(), name: String = "New Research", searchQueries: [SearchQuery] = [], selectedQuery: SearchQuery? = nil, showGeminiChat: Bool = false, selectedSpreadsheetForText: SavedSpreadsheet? = nil, isSearchHistoryTab: Bool = false, geminiMessages: [ChatMessage] = [], selectedSpreadsheetIds: Set<UUID> = [], spreadsheets: [SavedSpreadsheet] = [], cohortIds: Set<UUID> = [], selectedCohortIds: Set<UUID> = []) {
        self.id = id
        self.name = name
        self.searchQueries = searchQueries
        self.selectedQuery = selectedQuery
        self.showGeminiChat = showGeminiChat
        self.selectedSpreadsheetForText = selectedSpreadsheetForText
        self.isSearchHistoryTab = isSearchHistoryTab
        self.geminiMessages = geminiMessages
        self.selectedSpreadsheetIds = selectedSpreadsheetIds
        self.spreadsheets = spreadsheets
        self.cohortIds = cohortIds
        self.selectedCohortIds = selectedCohortIds
    }
    
    static func == (lhs: ResearchTab, rhs: ResearchTab) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.showGeminiChat == rhs.showGeminiChat &&
        lhs.selectedQuery?.id == rhs.selectedQuery?.id &&
        lhs.selectedSpreadsheetForText?.id == rhs.selectedSpreadsheetForText?.id &&
        lhs.isSearchHistoryTab == rhs.isSearchHistoryTab &&
        lhs.geminiMessages.count == rhs.geminiMessages.count &&
        lhs.selectedSpreadsheetIds == rhs.selectedSpreadsheetIds &&
        lhs.spreadsheets.count == rhs.spreadsheets.count &&
        lhs.cohortIds == rhs.cohortIds &&
        lhs.selectedCohortIds == rhs.selectedCohortIds &&
        lhs.searchQueries.count == rhs.searchQueries.count &&
        lhs.searchQueries.map { $0.id } == rhs.searchQueries.map { $0.id }
    }
    
    static let searchHistoryTabId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, name, searchQueries, selectedQuery, showGeminiChat
        case selectedSpreadsheetForText, isSearchHistoryTab, geminiMessages
        case selectedSpreadsheetIds, spreadsheets, cohortIds, selectedCohortIds
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        searchQueries = try container.decode([SearchQuery].self, forKey: .searchQueries)
        selectedQuery = try container.decodeIfPresent(SearchQuery.self, forKey: .selectedQuery)
        showGeminiChat = try container.decode(Bool.self, forKey: .showGeminiChat)
        selectedSpreadsheetForText = try container.decodeIfPresent(SavedSpreadsheet.self, forKey: .selectedSpreadsheetForText)
        isSearchHistoryTab = try container.decode(Bool.self, forKey: .isSearchHistoryTab)
        geminiMessages = try container.decode([ChatMessage].self, forKey: .geminiMessages)
        
        // Decode Set<UUID> as array
        let idsArray = try container.decode([UUID].self, forKey: .selectedSpreadsheetIds)
        selectedSpreadsheetIds = Set(idsArray)
        
        // Decode cohortIds (with fallback for older saved states)
        if let cohortIdsArray = try? container.decode([UUID].self, forKey: .cohortIds) {
            cohortIds = Set(cohortIdsArray)
        } else {
            cohortIds = []
        }
        
        // Decode selectedCohortIds (with fallback for older saved states)
        if let selectedCohortIdsArray = try? container.decode([UUID].self, forKey: .selectedCohortIds) {
            selectedCohortIds = Set(selectedCohortIdsArray)
        } else {
            selectedCohortIds = []
        }
        
        // Decode spreadsheets (with fallback for older saved states)
        if let spreadsheetsArray = try? container.decode([SavedSpreadsheet].self, forKey: .spreadsheets) {
            spreadsheets = spreadsheetsArray
        } else {
            spreadsheets = []
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(searchQueries, forKey: .searchQueries)
        try container.encodeIfPresent(selectedQuery, forKey: .selectedQuery)
        try container.encode(showGeminiChat, forKey: .showGeminiChat)
        try container.encodeIfPresent(selectedSpreadsheetForText, forKey: .selectedSpreadsheetForText)
        try container.encode(isSearchHistoryTab, forKey: .isSearchHistoryTab)
        try container.encode(geminiMessages, forKey: .geminiMessages)
        
        // Encode Set<UUID> as array
        try container.encode(Array(selectedSpreadsheetIds), forKey: .selectedSpreadsheetIds)
        try container.encode(spreadsheets, forKey: .spreadsheets)
        try container.encode(Array(cohortIds), forKey: .cohortIds)
        try container.encode(Array(selectedCohortIds), forKey: .selectedCohortIds)
    }
}
