//
//  DataAnalysisHubView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI

struct DataAnalysisHubView: View {
    @Binding var spreadsheets: [SavedSpreadsheet]
    @Binding var selectedSpreadsheetForText: SavedSpreadsheet?
    
    let spreadsheetExporter: SpreadsheetExporter
    let formatDate: (Date) -> String
    let onRefresh: () -> Void
    let onSelectForText: (SavedSpreadsheet) -> Void
    let onDelete: (SavedSpreadsheet) -> Void
    
    var body: some View {
        SpreadsheetListView(
            spreadsheets: $spreadsheets,
            spreadsheetExporter: spreadsheetExporter,
            onSelectForText: onSelectForText,
            onDelete: onDelete,
            formatDate: formatDate,
            isDragging: false
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
