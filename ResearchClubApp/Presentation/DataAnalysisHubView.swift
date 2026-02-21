//
//  DataAnalysisHubView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI

struct DataAnalysisHubView: View {
    @Binding var spreadsheets: [SavedSpreadsheet]
    @Binding var selectedSpreadsheetIds: Set<UUID>
    @Binding var selectedSpreadsheetForText: SavedSpreadsheet?
    @Binding var selectedCohortIds: Set<UUID>
    
    let cohorts: [Cohort]
    let currentTabCohortIds: Set<UUID>
    let spreadsheetExporter: SpreadsheetExporter
    let formatDate: (Date) -> String
    let allSpreadsheets: [SavedSpreadsheet] // All available spreadsheets for adding
    let onSelectForText: (SavedSpreadsheet) -> Void
    let onAddSpreadsheetToTab: (UUID) -> Void
    let onShowCohortManager: () -> Void
    let onRemoveFromTab: (Set<UUID>) -> Void
    let onAddCohortToTab: (UUID) -> Void
    let onRemoveCohortFromTab: (UUID) -> Void
    
    @State private var multiSelectMode = false
    @State private var selectedForRemoval: Set<UUID> = []
    @State private var showCohortPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with action buttons
            HStack {
                Text("Data Analysis Hub")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                HStack(spacing: 8) {
                    if multiSelectMode {
                        // Remove from tab button
                        if !selectedForRemoval.isEmpty {
                            Button(action: {
                                onRemoveFromTab(selectedForRemoval)
                                selectedForRemoval = []
                                multiSelectMode = false
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "minus.circle")
                                    Text("Remove from Tab (\(selectedForRemoval.count))")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(NSColor.controlBackgroundColor))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Cancel multi-select
                        Button(action: {
                            multiSelectMode = false
                            selectedForRemoval = []
                        }) {
                            Text("Cancel")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    } else {
                        // Multi-select button (only show if there are spreadsheets or cohorts)
                        if !spreadsheets.isEmpty || !cohorts.filter({ currentTabCohortIds.contains($0.id) }).isEmpty {
                            Button(action: {
                                multiSelectMode = true
                            }) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(width: 28, height: 36)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(NSColor.controlBackgroundColor))
                                    )
                            }
                            .buttonStyle(.plain)
                            .help("Select Multiple")
                        }
                        
                        // Add Spreadsheet button - direct access
                        let currentSpreadsheetIds = Set(spreadsheets.map { $0.id })
                        let availableSpreadsheets = allSpreadsheets.filter { !currentSpreadsheetIds.contains($0.id) }
                        if !availableSpreadsheets.isEmpty {
                            Menu {
                                ForEach(availableSpreadsheets.prefix(10)) { spreadsheet in
                                    Button(action: {
                                        onAddSpreadsheetToTab(spreadsheet.id)
                                    }) {
                                        Label(spreadsheet.displayName, systemImage: "doc.text")
                                    }
                                }
                                if availableSpreadsheets.count > 10 {
                                    Divider()
                                    Button(action: {
                                        onShowCohortManager()
                                    }) {
                                        Label("View All...", systemImage: "ellipsis.circle")
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Add Spreadsheet")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .frame(height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Add Cohort button
                        Button(action: {
                            showCohortPicker.toggle()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "tray.2.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Add Cohort")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .frame(height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color.purple.opacity(0.3), radius: 4, x: 0, y: 2)
                            )
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showCohortPicker, arrowEdge: .bottom) {
                            CohortPickerView(
                                cohorts: cohorts,
                                currentTabCohortIds: currentTabCohortIds,
                                onAddCohort: { cohortId in
                                    onAddCohortToTab(cohortId)
                                    showCohortPicker = false
                                },
                                onManageCohorts: {
                                    showCohortPicker = false
                                    onShowCohortManager()
                                }
                            )
                            .frame(width: 320, height: 400)
                        }
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .overlay(
                // Bottom border
                VStack {
                    Spacer()
                    Divider()
                }
            )
            
            SpreadsheetListView(
                spreadsheets: $spreadsheets,
                selectedSpreadsheetIds: $selectedSpreadsheetIds,
                cohorts: cohorts.filter { currentTabCohortIds.contains($0.id) },
                allSpreadsheets: allSpreadsheets,
                spreadsheetExporter: spreadsheetExporter,
                onSelectForText: onSelectForText,
                onDelete: { _ in }, // Not used - deletion moved to settings
                onRemoveFromTab: { spreadsheetId in
                    onRemoveFromTab([spreadsheetId])
                },
                formatDate: formatDate,
                isDragging: false,
                multiSelectMode: multiSelectMode,
                selectedForRemoval: $selectedForRemoval,
                selectedCohortIds: $selectedCohortIds,
                onRemoveCohort: onRemoveCohortFromTab
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
