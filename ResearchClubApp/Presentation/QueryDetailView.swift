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
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern Header with back button
            HStack(spacing: 16) {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13))
                        Text("Back")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(query.displayName)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Placeholder for alignment
                Color.clear
                    .frame(width: 80)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Data view
            StockDataResultsView(
                aggregates: query.aggregates,
                ticker: query.ticker,
                tickerDetails: query.tickerDetails
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
