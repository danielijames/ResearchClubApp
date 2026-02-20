//
//  SearchQueriesListView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI

struct SearchQueriesListView: View {
    let searchQueries: [SearchQuery]
    let onSelectQuery: (SearchQuery) -> Void
    let onClearAll: () -> Void
    let formatDate: (Date) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Modern Header
            HStack {
                Text("Search History")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                if !searchQueries.isEmpty {
                    Button(action: onClearAll) {
                        Text("Clear All")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // List of queries
            if searchQueries.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("No Searches Yet")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("Enter a ticker and fetch data to get started")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(searchQueries) { query in
                    Button(action: {
                        onSelectQuery(query)
                    }) {
                        HStack(spacing: 12) {
                            // Ticker badge
                            Text(query.ticker.uppercased())
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(query.displayName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                HStack(spacing: 8) {
                                    Text("\(query.aggregates.count) points")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Text(formatDate(query.date))
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
