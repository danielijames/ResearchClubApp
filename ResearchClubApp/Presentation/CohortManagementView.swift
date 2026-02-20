//
//  CohortManagementView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI

struct CohortManagementView: View {
    @Binding var cohorts: [Cohort]
    let spreadsheets: [SavedSpreadsheet]
    let currentTab: ResearchTab?
    let onAssignCohortsToTab: (Set<UUID>) -> Void
    
    @State private var selectedCohort: Cohort?
    @State private var isCreatingNewCohort = false
    @State private var newCohortName = ""
    @State private var newCohortColor: CohortColor = .blue
    @State private var newCohortDescription = ""
    @Environment(\.dismiss) private var dismiss
    
    private var currentTabCohortIds: Set<UUID> {
        currentTab?.cohortIds ?? []
    }
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Left: Cohorts List
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        Text("Cohorts")
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                        Button(action: {
                            isCreatingNewCohort = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(width: 28, height: 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(NSColor.controlBackgroundColor))
                                )
                        }
                        .buttonStyle(.plain)
                        .help("New Cohort")
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    
                    Divider()
                    
                    // Cohorts List
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(cohorts) { cohort in
                                CohortRowView(
                                    cohort: cohort,
                                    isSelected: selectedCohort?.id == cohort.id,
                                    isAssignedToTab: currentTabCohortIds.contains(cohort.id),
                                    spreadsheetCount: cohort.spreadsheetIds.count,
                                    onSelect: {
                                        selectedCohort = cohort
                                    }
                                )
                            }
                            
                            if cohorts.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    Text("No Cohorts")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Text("Create a cohort to organize your spreadsheets")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding()
                    }
                }
                .frame(width: 300)
                .background(Color(NSColor.windowBackgroundColor))
                
                Divider()
                
                // Right: Cohort Details or Create Form
                if isCreatingNewCohort {
                    CreateCohortView(
                        name: $newCohortName,
                        color: $newCohortColor,
                        description: $newCohortDescription,
                        onSave: {
                            let newCohort = Cohort(
                                name: newCohortName,
                                color: newCohortColor,
                                description: newCohortDescription.isEmpty ? nil : newCohortDescription
                            )
                            cohorts.append(newCohort)
                            selectedCohort = newCohort
                            isCreatingNewCohort = false
                            newCohortName = ""
                            newCohortDescription = ""
                        },
                        onCancel: {
                            isCreatingNewCohort = false
                            newCohortName = ""
                            newCohortDescription = ""
                        }
                    )
                } else if let cohort = selectedCohort {
                    CohortDetailView(
                        cohort: Binding(
                            get: { cohort },
                            set: { updated in
                                if let index = cohorts.firstIndex(where: { $0.id == cohort.id }) {
                                    cohorts[index] = updated
                                    selectedCohort = updated
                                }
                            }
                        ),
                        spreadsheets: spreadsheets,
                        isAssignedToTab: currentTabCohortIds.contains(cohort.id),
                        hasCurrentTab: currentTab != nil,
                        onToggleAssignment: {
                            guard let tab = currentTab else { return }
                            var updatedIds = tab.cohortIds
                            if updatedIds.contains(cohort.id) {
                                updatedIds.remove(cohort.id)
                            } else {
                                updatedIds.insert(cohort.id)
                            }
                            onAssignCohortsToTab(updatedIds)
                        }
                    )
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "tray.2")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Select a Cohort")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Choose a cohort from the list to view and edit its details")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Cohort Manager")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 900, height: 600)
    }
}

struct CohortRowView: View {
    let cohort: Cohort
    let isSelected: Bool
    let isAssignedToTab: Bool
    let spreadsheetCount: Int
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Color indicator
                Circle()
                    .fill(cohort.color.color)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(cohort.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Label("\(spreadsheetCount)", systemImage: "doc.text")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        if isAssignedToTab {
                            Label("Assigned", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CreateCohortView: View {
    @Binding var name: String
    @Binding var color: CohortColor
    @Binding var description: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("New Cohort")
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.bottom, 8)
                
                // Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    TextField("Enter cohort name", text: $name)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        )
                }
                
                // Color
                VStack(alignment: .leading, spacing: 8) {
                    Text("Color")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    HStack(spacing: 12) {
                        ForEach(CohortColor.allCases) { cohortColor in
                            Button(action: {
                                color = cohortColor
                            }) {
                                Circle()
                                    .fill(cohortColor.color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(color == cohortColor ? Color.primary : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (Optional)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    TextEditor(text: $description)
                        .font(.system(size: 13))
                        .frame(height: 80)
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        )
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (Optional)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    TextEditor(text: $description)
                        .font(.system(size: 13))
                        .frame(height: 80)
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        )
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 12) {
                    Button("Cancel", action: onCancel)
                        .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Create", action: onSave)
                        .buttonStyle(.borderedProminent)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct CohortDetailView: View {
    @Binding var cohort: Cohort
    let spreadsheets: [SavedSpreadsheet]
    let isAssignedToTab: Bool
    let hasCurrentTab: Bool
    let onToggleAssignment: () -> Void
    
    @State private var isEditing = false
    @State private var editedName: String = ""
    @State private var editedColor: CohortColor = .blue
    @State private var editedDescription: String = ""
    @State private var showSpreadsheetPicker = false
    
    private var cohortSpreadsheets: [SavedSpreadsheet] {
        spreadsheets.filter { cohort.spreadsheetIds.contains($0.id) }
    }
    
    private var availableSpreadsheets: [SavedSpreadsheet] {
        spreadsheets.filter { !cohort.spreadsheetIds.contains($0.id) }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        if isEditing {
                            TextField("Cohort name", text: $editedName)
                                .textFieldStyle(.plain)
                                .font(.system(size: 20, weight: .semibold))
                                .padding(8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                            
                            // Color picker when editing
                            HStack(spacing: 12) {
                                Text("Color:")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                ForEach(CohortColor.allCases) { cohortColor in
                                    Button(action: {
                                        editedColor = cohortColor
                                    }) {
                                        Circle()
                                            .fill(cohortColor.color)
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Circle()
                                                    .stroke(editedColor == cohortColor ? Color.primary : Color.clear, lineWidth: 2)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } else {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(cohort.color.color)
                                    .frame(width: 16, height: 16)
                                Text(cohort.name)
                                    .font(.system(size: 20, weight: .semibold))
                            }
                        }
                        
                        if !isEditing, let description = cohort.description, !description.isEmpty {
                            Text(description)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        // Description editor when editing
                        if isEditing {
                            TextEditor(text: $editedDescription)
                                .font(.system(size: 13))
                                .frame(height: 60)
                                .padding(8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                )
                        }
                    }
                    
                    Spacer()
                    
                    // Assign to tab button
                    Button(action: onToggleAssignment) {
                        HStack(spacing: 6) {
                            Image(systemName: isAssignedToTab ? "checkmark.circle.fill" : "plus.circle")
                            Text(isAssignedToTab ? "Assigned" : "Assign to Tab")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isAssignedToTab ? .green : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isAssignedToTab ? Color.green.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Edit button
                    Button(action: {
                        if isEditing {
                            // Save changes
                            cohort.name = editedName
                            cohort.color = editedColor
                            cohort.description = editedDescription.isEmpty ? nil : editedDescription
                        } else {
                            // Start editing
                            editedName = cohort.name
                            editedColor = cohort.color
                            editedDescription = cohort.description ?? ""
                        }
                        isEditing.toggle()
                    }) {
                        Image(systemName: isEditing ? "checkmark" : "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(NSColor.controlBackgroundColor))
                            )
                    }
                    .buttonStyle(.plain)
                }
                
                Divider()
                
                // Spreadsheets in cohort
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Spreadsheets (\(cohortSpreadsheets.count))")
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                        Button(action: {
                            showSpreadsheetPicker = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                                .frame(width: 24, height: 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(NSColor.controlBackgroundColor))
                                )
                        }
                        .buttonStyle(.plain)
                        .help("Add spreadsheets")
                        .sheet(isPresented: $showSpreadsheetPicker) {
                            SpreadsheetPickerView(
                                availableSpreadsheets: availableSpreadsheets,
                                onSelect: { spreadsheetIds in
                                    cohort.spreadsheetIds.formUnion(spreadsheetIds)
                                }
                            )
                        }
                    }
                    
                    if cohortSpreadsheets.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 30))
                                .foregroundColor(.secondary)
                            Text("No spreadsheets")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Add spreadsheets to this cohort")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(cohortSpreadsheets) { spreadsheet in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(spreadsheet.displayName)
                                        .font(.system(size: 13, weight: .medium))
                                    Text("\(spreadsheet.dataPointCount) points")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button(action: {
                                    cohort.spreadsheetIds.remove(spreadsheet.id)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(NSColor.controlBackgroundColor))
                            )
                        }
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            editedName = cohort.name
            editedColor = cohort.color
            editedDescription = cohort.description ?? ""
        }
    }
}
