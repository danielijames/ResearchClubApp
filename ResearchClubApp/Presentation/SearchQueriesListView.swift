//
//  SearchQueriesListView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI

struct SearchQueriesListView: View {
    @Binding var searchQueries: [SearchQuery]
    let onSelectQuery: (SearchQuery) -> Void
    let onClearAll: () -> Void
    let onDelete: (Set<UUID>) -> Void
    let onMove: (IndexSet, Int) -> Void
    let formatDate: (Date) -> String
    
    @State private var multiSelectMode = false
    @State private var selectedQueryIds: Set<UUID> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Modern Header
            HStack {
                Text("Search History")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                
                if multiSelectMode {
                    // Multi-select mode actions
                    if !selectedQueryIds.isEmpty {
                        Button(action: {
                            onDelete(selectedQueryIds)
                            selectedQueryIds.removeAll()
                            multiSelectMode = false
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                Text("Delete (\(selectedQueryIds.count))")
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.red.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button(action: {
                        multiSelectMode = false
                        selectedQueryIds.removeAll()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                } else {
                    // Normal mode actions
                    if !searchQueries.isEmpty {
                        Button(action: {
                            multiSelectMode = true
                        }) {
                            Text("EDIT")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(NSColor.controlBackgroundColor))
                                )
                        }
                        .buttonStyle(.plain)
                        .help("Edit")
                        
                        Button(action: onClearAll) {
                            Text("Clear All")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
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
                List {
                    ForEach(searchQueries) { query in
                        SearchQueryRowView(
                            query: query,
                            multiSelectMode: multiSelectMode,
                            isSelected: Binding(
                                get: { selectedQueryIds.contains(query.id) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedQueryIds.insert(query.id)
                                    } else {
                                        selectedQueryIds.remove(query.id)
                                    }
                                }
                            ),
                            formatDate: formatDate,
                            onSelect: {
                                if !multiSelectMode {
                                    onSelectQuery(query)
                                } else {
                                    if selectedQueryIds.contains(query.id) {
                                        selectedQueryIds.remove(query.id)
                                    } else {
                                        selectedQueryIds.insert(query.id)
                                    }
                                }
                            }
                        )
                    }
                    .onDelete { indexSet in
                        let idsToDelete = indexSet.map { searchQueries[$0].id }
                        onDelete(Set(idsToDelete))
                    }
                    .onMove(perform: onMove)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SearchQueryRowView: View {
    let query: SearchQuery
    let multiSelectMode: Bool
    @Binding var isSelected: Bool
    let formatDate: (Date) -> String
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                if multiSelectMode {
                    // Multi-select checkbox
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? .blue : .secondary)
                        .frame(width: 24)
                }
                
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
                
                if !multiSelectMode {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(
                multiSelectMode && isSelected ? Color.blue.opacity(0.1) : Color.clear
            )
        }
        .buttonStyle(.plain)
    }
}
