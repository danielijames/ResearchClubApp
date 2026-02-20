//
//  ResearchTab.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation

struct ResearchTab: Identifiable, Equatable {
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
}
