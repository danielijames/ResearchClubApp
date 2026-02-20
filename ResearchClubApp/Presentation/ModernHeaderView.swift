//
//  ModernHeaderView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI

struct ModernHeaderView: View {
    @Binding var showDataAnalysisHub: Bool
    var onToggleDataAnalysisHub: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Spacer to account for Settings button in top left
            Spacer()
                .frame(width: 100) // Approximate width of Settings button
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: 12) {
                // Ask Gemini! button - clean and simple
                Button(action: {
                    showDataAnalysisHub.toggle()
                    onToggleDataAnalysisHub()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13))
                        Text("Ask Gemini!")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(showDataAnalysisHub ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(showDataAnalysisHub ? Color.purple : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Color(NSColor.controlBackgroundColor)
                .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
        )
    }
}
