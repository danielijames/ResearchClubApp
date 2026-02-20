//
//  DeletionManagerView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI

struct DeletionManagerView: View {
    @Binding var cohorts: [Cohort]
    @Binding var spreadsheets: [SavedSpreadsheet]
    let spreadsheetExporter: SpreadsheetExporter
    let onCohortDeleted: (UUID) -> Void
    let onSpreadsheetDeleted: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: DeletionTab = .spreadsheets
    @State private var selectedSpreadsheetIds: Set<UUID> = []
    @State private var selectedCohortIds: Set<UUID> = []
    @State private var showDeleteConfirmation = false
    @State private var pendingDeletions: PendingDeletions?
    
    enum DeletionTab {
        case spreadsheets
        case cohorts
    }
    
    struct PendingDeletions {
        let spreadsheetIds: Set<UUID>
        let cohortIds: Set<UUID>
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                HStack(spacing: 0) {
                    Button(action: {
                        selectedTab = .spreadsheets
                        selectedSpreadsheetIds = []
                    }) {
                        Text("Spreadsheets")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedTab == .spreadsheets ? .primary : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                selectedTab == .spreadsheets ? Color(NSColor.controlBackgroundColor) : Color.clear
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        selectedTab = .cohorts
                        selectedCohortIds = []
                    }) {
                        Text("Cohorts")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedTab == .cohorts ? .primary : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                selectedTab == .cohorts ? Color(NSColor.controlBackgroundColor) : Color.clear
                            )
                    }
                    .buttonStyle(.plain)
                }
                .background(Color(NSColor.windowBackgroundColor))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(NSColor.separatorColor)),
                    alignment: .bottom
                )
                
                Divider()
                
                // Content
                if selectedTab == .spreadsheets {
                    SpreadsheetDeletionView(
                        spreadsheets: spreadsheets,
                        selectedIds: $selectedSpreadsheetIds,
                        formatDate: formatDate,
                        onDelete: { ids in
                            pendingDeletions = PendingDeletions(spreadsheetIds: ids, cohortIds: [])
                            showDeleteConfirmation = true
                        }
                    )
                } else {
                    CohortDeletionView(
                        cohorts: cohorts,
                        selectedIds: $selectedCohortIds,
                        onDelete: { ids in
                            pendingDeletions = PendingDeletions(spreadsheetIds: [], cohortIds: ids)
                            showDeleteConfirmation = true
                        }
                    )
                }
            }
            .navigationTitle("Deletion Manager")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Confirm Deletion", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    pendingDeletions = nil
                }
                Button("Delete", role: .destructive) {
                    if let deletions = pendingDeletions {
                        performDeletions(deletions)
                    }
                    pendingDeletions = nil
                }
            } message: {
                if let deletions = pendingDeletions {
                    var message = ""
                    if !deletions.spreadsheetIds.isEmpty {
                        message += "\(deletions.spreadsheetIds.count) spreadsheet\(deletions.spreadsheetIds.count == 1 ? "" : "s") will be permanently deleted.\n\n"
                    }
                    if !deletions.cohortIds.isEmpty {
                        message += "\(deletions.cohortIds.count) cohort\(deletions.cohortIds.count == 1 ? "" : "s") will be permanently deleted.\n\n"
                    }
                    message += "This action cannot be undone."
                    return Text(message)
                }
                return Text("")
            }
        }
        .frame(width: 800, height: 600)
    }
    
    private func performDeletions(_ deletions: PendingDeletions) {
        // Delete spreadsheets
        for spreadsheetId in deletions.spreadsheetIds {
            if let spreadsheet = spreadsheets.first(where: { $0.id == spreadsheetId }) {
                do {
                    try spreadsheetExporter.deleteSpreadsheet(spreadsheet)
                    spreadsheets.removeAll { $0.id == spreadsheetId }
                } catch {
                    print("❌ Failed to delete spreadsheet: \(error.localizedDescription)")
                }
            }
        }
        
        // Delete cohorts
        for cohortId in deletions.cohortIds {
            cohorts.removeAll { $0.id == cohortId }
            onCohortDeleted(cohortId)
        }
        
        onSpreadsheetDeleted()
    }
}

struct SpreadsheetDeletionView: View {
    let spreadsheets: [SavedSpreadsheet]
    @Binding var selectedIds: Set<UUID>
    let formatDate: (Date) -> String
    let onDelete: (Set<UUID>) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("\(selectedIds.count) selected")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !selectedIds.isEmpty {
                    Button(action: {
                        onDelete(selectedIds)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Delete Selected")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Spreadsheet list
            if spreadsheets.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No Spreadsheets")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("There are no spreadsheets to delete")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(spreadsheets) { spreadsheet in
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
                                        .foregroundColor(selectedIds.contains(spreadsheet.id) ? .red : .secondary)
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
                                    .fill(selectedIds.contains(spreadsheet.id) ? Color.red.opacity(0.1) : Color(NSColor.windowBackgroundColor))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedIds.contains(spreadsheet.id) ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
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
    }
}

struct CohortDeletionView: View {
    let cohorts: [Cohort]
    @Binding var selectedIds: Set<UUID>
    let onDelete: (Set<UUID>) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("\(selectedIds.count) selected")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !selectedIds.isEmpty {
                    Button(action: {
                        onDelete(selectedIds)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Delete Selected")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Cohort list
            if cohorts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No Cohorts")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("There are no cohorts to delete")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(cohorts) { cohort in
                            HStack {
                                Button(action: {
                                    if selectedIds.contains(cohort.id) {
                                        selectedIds.remove(cohort.id)
                                    } else {
                                        selectedIds.insert(cohort.id)
                                    }
                                }) {
                                    Image(systemName: selectedIds.contains(cohort.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 16))
                                        .foregroundColor(selectedIds.contains(cohort.id) ? .red : .secondary)
                                }
                                .buttonStyle(.plain)
                                
                                Circle()
                                    .fill(cohort.color.color)
                                    .frame(width: 12, height: 12)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(cohort.name)
                                        .font(.system(size: 14, weight: .medium))
                                    Label("\(cohort.spreadsheetIds.count) spreadsheets", systemImage: "doc.text")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedIds.contains(cohort.id) ? Color.red.opacity(0.1) : Color(NSColor.windowBackgroundColor))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedIds.contains(cohort.id) ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedIds.contains(cohort.id) {
                                    selectedIds.remove(cohort.id)
                                } else {
                                    selectedIds.insert(cohort.id)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
