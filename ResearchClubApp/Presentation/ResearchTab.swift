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
    
    init(id: UUID = UUID(), name: String = "New Research", searchQueries: [SearchQuery] = [], selectedQuery: SearchQuery? = nil, showGeminiChat: Bool = false, selectedSpreadsheetForText: SavedSpreadsheet? = nil, isSearchHistoryTab: Bool = false, geminiMessages: [ChatMessage] = [], selectedSpreadsheetIds: Set<UUID> = []) {
        self.id = id
        self.name = name
        self.searchQueries = searchQueries
        self.selectedQuery = selectedQuery
        self.showGeminiChat = showGeminiChat
        self.selectedSpreadsheetForText = selectedSpreadsheetForText
        self.isSearchHistoryTab = isSearchHistoryTab
        self.geminiMessages = geminiMessages
        self.selectedSpreadsheetIds = selectedSpreadsheetIds
    }
    
    static func == (lhs: ResearchTab, rhs: ResearchTab) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.showGeminiChat == rhs.showGeminiChat &&
        lhs.selectedQuery?.id == rhs.selectedQuery?.id &&
        lhs.selectedSpreadsheetForText?.id == rhs.selectedSpreadsheetForText?.id &&
        lhs.isSearchHistoryTab == rhs.isSearchHistoryTab &&
        lhs.geminiMessages.count == rhs.geminiMessages.count &&
        lhs.selectedSpreadsheetIds == rhs.selectedSpreadsheetIds
    }
    
    static let searchHistoryTabId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, name, searchQueries, selectedQuery, showGeminiChat
        case selectedSpreadsheetForText, isSearchHistoryTab, geminiMessages
        case selectedSpreadsheetIds
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
    }
}
