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
    let spreadsheetExporter: SpreadsheetExporter
    let onSelectForText: (SavedSpreadsheet) -> Void
    let onDelete: (SavedSpreadsheet) -> Void
    let formatDate: (Date) -> String
    let isDragging: Bool
    
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
                                onDelete: onDelete
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
    
    var body: some View {
        HStack(spacing: 16) {
            // Selection indicator
            Circle()
                .fill(isSelected ? Color.purple : Color.clear)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.purple : Color(NSColor.separatorColor), lineWidth: 2)
                        .frame(width: 12, height: 12)
                )
            
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
            
            // Action buttons
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
                
                Button(action: {
                    onDelete(spreadsheet)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .frame(width: 28, height: 28)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help("Delete")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.purple.opacity(0.1) : Color(NSColor.windowBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.purple.opacity(0.3) : Color(NSColor.separatorColor).opacity(0.5), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            // Toggle selection on tap
            isSelected.toggle()
        }
        .help(isSelected ? "Selected for Gemini analysis" : "Tap to select for Gemini analysis")
    }
}
