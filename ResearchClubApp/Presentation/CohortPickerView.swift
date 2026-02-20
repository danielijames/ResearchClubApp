//
//  CohortPickerView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI

struct CohortPickerView: View {
    let cohorts: [Cohort]
    let currentTabCohortIds: Set<UUID>
    let onAddCohort: (UUID) -> Void
    let onManageCohorts: () -> Void
    
    var availableCohorts: [Cohort] {
        cohorts.filter { !currentTabCohortIds.contains($0.id) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Cohort")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button(action: onManageCohorts) {
                    Text("Manage")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.purple)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            if availableCohorts.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Available Cohorts")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Create cohorts in the Cohort Manager to add them here")
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
                        ForEach(availableCohorts) { cohort in
                            CohortPickerRowView(
                                cohort: cohort,
                                onAdd: {
                                    onAddCohort(cohort.id)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct CohortPickerRowView: View {
    let cohort: Cohort
    let onAdd: () -> Void
    
    var body: some View {
        Button(action: onAdd) {
            HStack(spacing: 12) {
                // Color badge
                RoundedRectangle(cornerRadius: 6)
                    .fill(cohort.color.color)
                    .frame(width: 4, height: 40)
                
                // Icon
                ZStack {
                    Circle()
                        .fill(cohort.color.color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "tray.2.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(cohort.color.color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(cohort.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Label("\(cohort.spreadsheetIds.count)", systemImage: "doc.text")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        if let description = cohort.description, !description.isEmpty {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(description)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                // Add button
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(cohort.color.color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(cohort.color.color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
