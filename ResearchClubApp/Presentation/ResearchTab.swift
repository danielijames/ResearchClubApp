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
    
    init(id: UUID = UUID(), name: String = "New Research", searchQueries: [SearchQuery] = [], selectedQuery: SearchQuery? = nil, showGeminiChat: Bool = false, selectedSpreadsheetForText: SavedSpreadsheet? = nil, isSearchHistoryTab: Bool = false) {
        self.id = id
        self.name = name
        self.searchQueries = searchQueries
        self.selectedQuery = selectedQuery
        self.showGeminiChat = showGeminiChat
        self.selectedSpreadsheetForText = selectedSpreadsheetForText
        self.isSearchHistoryTab = isSearchHistoryTab
    }
    
    static func == (lhs: ResearchTab, rhs: ResearchTab) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.showGeminiChat == rhs.showGeminiChat &&
        lhs.selectedQuery?.id == rhs.selectedQuery?.id &&
        lhs.selectedSpreadsheetForText?.id == rhs.selectedSpreadsheetForText?.id &&
        lhs.isSearchHistoryTab == rhs.isSearchHistoryTab
    }
    
    static let searchHistoryTabId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
}
