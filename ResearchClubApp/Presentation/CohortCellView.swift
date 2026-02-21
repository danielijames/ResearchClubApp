//
//  CohortCellView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI

struct CohortCellView: View {
    let cohort: Cohort
    let spreadsheets: [SavedSpreadsheet]
    let multiSelectMode: Bool
    @Binding var isSelectedForGemini: Bool
    @Binding var isSelectedForRemoval: Bool
    let onRemove: () -> Void
    
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
                // Selection indicator for Gemini (similar to spreadsheets, more subtle)
                Circle()
                    .fill(isSelectedForGemini ? Color.purple : Color.clear)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(isSelectedForGemini ? Color.purple : Color(NSColor.separatorColor), lineWidth: 2)
                            .frame(width: 12, height: 12)
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(cohort.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    // Subtle color badge
                    RoundedRectangle(cornerRadius: 2)
                        .fill(cohort.color.color.opacity(0.6))
                        .frame(width: 4, height: 4)
                }
                
                HStack(spacing: 8) {
                    Label("\(spreadsheets.count) spreadsheets", systemImage: "doc.text.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    if let description = cohort.description, !description.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons (hidden in multi-select mode)
            if !multiSelectMode {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
                .help("Remove from tab")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(height: 70)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.windowBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            multiSelectMode && isSelectedForRemoval ? Color.orange.opacity(0.4) :
                            isSelectedForGemini ? cohort.color.color.opacity(0.4) :
                            Color(NSColor.separatorColor).opacity(0.5),
                            lineWidth: multiSelectMode && isSelectedForRemoval ? 2 : 
                            isSelectedForGemini ? 2 : 1
                        )
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if multiSelectMode {
                isSelectedForRemoval.toggle()
            } else {
                // Toggle selection for Gemini analysis
                isSelectedForGemini.toggle()
            }
        }
        .help(
            multiSelectMode ?
            (isSelectedForRemoval ? "Selected for removal" : "Tap to select for removal") :
            (isSelectedForGemini ? "Selected for Gemini analysis" : "Tap to select for Gemini analysis")
        )
    }
}
