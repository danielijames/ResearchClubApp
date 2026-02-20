//
//  SpreadsheetListView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI
import AppKit

struct SpreadsheetListView: View {
    @Binding var spreadsheets: [SavedSpreadsheet]
    @Binding var selectedSpreadsheetIds: Set<UUID>
    let cohorts: [Cohort]
    let spreadsheetExporter: SpreadsheetExporter
    let onSelectForText: (SavedSpreadsheet) -> Void
    let onDelete: (SavedSpreadsheet) -> Void
    let formatDate: (Date) -> String
    let isDragging: Bool
    var multiSelectMode: Bool = false
    @Binding var selectedForRemoval: Set<UUID>
    @Binding var selectedCohortIds: Set<UUID>
    let onRemoveCohort: (UUID) -> Void
    
    init(
        spreadsheets: Binding<[SavedSpreadsheet]>,
        selectedSpreadsheetIds: Binding<Set<UUID>>,
        cohorts: [Cohort] = [],
        spreadsheetExporter: SpreadsheetExporter,
        onSelectForText: @escaping (SavedSpreadsheet) -> Void,
        onDelete: @escaping (SavedSpreadsheet) -> Void,
        formatDate: @escaping (Date) -> String,
        isDragging: Bool,
        multiSelectMode: Bool = false,
        selectedForRemoval: Binding<Set<UUID>> = .constant([]),
        selectedCohortIds: Binding<Set<UUID>> = .constant([]),
        onRemoveCohort: @escaping (UUID) -> Void = { _ in }
    ) {
        self._spreadsheets = spreadsheets
        self._selectedSpreadsheetIds = selectedSpreadsheetIds
        self.cohorts = cohorts
        self.spreadsheetExporter = spreadsheetExporter
        self.onSelectForText = onSelectForText
        self.onDelete = onDelete
        self.formatDate = formatDate
        self.isDragging = isDragging
        self.multiSelectMode = multiSelectMode
        self._selectedForRemoval = selectedForRemoval
        self._selectedCohortIds = selectedCohortIds
        self.onRemoveCohort = onRemoveCohort
    }
    
    var body: some View {
        Group {
            if spreadsheets.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No Data Available")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Fetched stock data will be automatically saved and available for analysis")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        // Cohorts first (styled differently)
                        ForEach(cohorts) { cohort in
                            CohortCellView(
                                cohort: cohort,
                                spreadsheets: spreadsheets.filter { cohort.spreadsheetIds.contains($0.id) },
                                multiSelectMode: multiSelectMode,
                                isSelectedForGemini: Binding(
                                    get: { selectedCohortIds.contains(cohort.id) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedCohortIds.insert(cohort.id)
                                        } else {
                                            selectedCohortIds.remove(cohort.id)
                                        }
                                    }
                                ),
                                isSelectedForRemoval: Binding(
                                    get: { selectedForRemoval.contains(cohort.id) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedForRemoval.insert(cohort.id)
                                        } else {
                                            selectedForRemoval.remove(cohort.id)
                                        }
                                    }
                                ),
                                onRemove: {
                                    onRemoveCohort(cohort.id)
                                }
                            )
                        }
                        
                        // Then individual spreadsheets
                        ForEach($spreadsheets) { $spreadsheet in
                            SpreadsheetCellView(
                                spreadsheet: $spreadsheet,
                                isSelected: Binding(
                                    get: { selectedSpreadsheetIds.contains(spreadsheet.id) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedSpreadsheetIds.insert(spreadsheet.id)
                                        } else {
                                            selectedSpreadsheetIds.remove(spreadsheet.id)
                                        }
                                    }
                                ),
                                spreadsheetExporter: spreadsheetExporter,
                                formatDate: formatDate,
                                onSelectForText: onSelectForText,
                                onDelete: onDelete,
                                multiSelectMode: multiSelectMode,
                                isSelectedForRemoval: Binding(
                                    get: { selectedForRemoval.contains(spreadsheet.id) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedForRemoval.insert(spreadsheet.id)
                                        } else {
                                            selectedForRemoval.remove(spreadsheet.id)
                                        }
                                    }
                                )
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .layoutPriority(isDragging ? 0 : 1)
        .allowsHitTesting(!isDragging)
    }
}

struct SpreadsheetCellView: View {
    @Binding var spreadsheet: SavedSpreadsheet
    @Binding var isSelected: Bool
    let spreadsheetExporter: SpreadsheetExporter
    let formatDate: (Date) -> String
    let onSelectForText: (SavedSpreadsheet) -> Void
    let onDelete: (SavedSpreadsheet) -> Void
    let multiSelectMode: Bool
    @Binding var isSelectedForRemoval: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            if multiSelectMode {
                // Multi-select checkbox for removal
                Button(action: {
                    isSelectedForRemoval.toggle()
                }) {
                    Image(systemName: isSelectedForRemoval ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundColor(isSelectedForRemoval ? .orange : .secondary)
                }
                .buttonStyle(.plain)
            } else {
                // Selection indicator for Gemini
                Circle()
                    .fill(isSelected ? Color.purple : Color.clear)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.purple : Color(NSColor.separatorColor), lineWidth: 2)
                            .frame(width: 12, height: 12)
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(spreadsheet.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Label("\(spreadsheet.dataPointCount) points", systemImage: "chart.bar.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Label(formatDate(spreadsheet.createdAt), systemImage: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Action buttons (hidden in multi-select mode)
            if !multiSelectMode {
                HStack(spacing: 8) {
                    Button(action: {
                        onSelectForText(spreadsheet)
                    }) {
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help("View as Text")
                    
                    Button(action: {
                        NSWorkspace.shared.activateFileViewerSelecting([spreadsheet.fileURL])
                    }) {
                        Image(systemName: "folder")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help("Show in Finder")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    multiSelectMode && isSelectedForRemoval ? Color.orange.opacity(0.1) :
                    isSelected ? Color.purple.opacity(0.1) : Color(NSColor.windowBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            multiSelectMode && isSelectedForRemoval ? Color.orange.opacity(0.3) :
                            isSelected ? Color.purple.opacity(0.3) : Color(NSColor.separatorColor).opacity(0.5),
                            lineWidth: 1
                        )
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if multiSelectMode {
                isSelectedForRemoval.toggle()
            } else {
                // Toggle selection for Gemini analysis
                isSelected.toggle()
            }
        }
        .help(
            multiSelectMode ?
            (isSelectedForRemoval ? "Selected for removal" : "Tap to select for removal") :
            (isSelected ? "Selected for Gemini analysis" : "Tap to select for Gemini analysis")
        )
    }
}
