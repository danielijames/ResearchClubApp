//
//  SpreadsheetPickerView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI

struct SpreadsheetPickerView: View {
    let availableSpreadsheets: [SavedSpreadsheet]
    let onSelect: (Set<UUID>) -> Void
    
    @State private var selectedIds: Set<UUID> = []
    @Environment(\.dismiss) private var dismiss
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if availableSpreadsheets.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No Available Spreadsheets")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("All spreadsheets are already in this cohort")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(availableSpreadsheets) { spreadsheet in
                                HStack {
                                    Button(action: {
                                        if selectedIds.contains(spreadsheet.id) {
                                            selectedIds.remove(spreadsheet.id)
                                        } else {
                                            selectedIds.insert(spreadsheet.id)
                                        }
                                    }) {
                                        Image(systemName: selectedIds.contains(spreadsheet.id) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 16))
                                            .foregroundColor(selectedIds.contains(spreadsheet.id) ? .accentColor : .secondary)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(spreadsheet.displayName)
                                            .font(.system(size: 14, weight: .medium))
                                        HStack(spacing: 8) {
                                            Label("\(spreadsheet.dataPointCount) points", systemImage: "chart.bar.fill")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                            Text("•")
                                                .foregroundColor(.secondary)
                                            Label(formatDate(spreadsheet.createdAt), systemImage: "clock")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedIds.contains(spreadsheet.id) ? Color.accentColor.opacity(0.1) : Color(NSColor.windowBackgroundColor))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedIds.contains(spreadsheet.id) ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if selectedIds.contains(spreadsheet.id) {
                                        selectedIds.remove(spreadsheet.id)
                                    } else {
                                        selectedIds.insert(spreadsheet.id)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Add Spreadsheets")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSelect(selectedIds)
                        dismiss()
                    }
                    .disabled(selectedIds.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 500)
    }
}
