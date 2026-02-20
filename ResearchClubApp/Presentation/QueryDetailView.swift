//
//  QueryDetailView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI
import AppKit

struct QueryDetailView: View {
    let query: SearchQuery
    
    var body: some View {
        ScrollView {
            StockDataResultsView(
                aggregates: query.aggregates,
                ticker: query.ticker,
                tickerDetails: query.tickerDetails
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
