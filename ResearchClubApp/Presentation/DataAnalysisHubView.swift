//
//  DataAnalysisHubView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI

struct DataAnalysisHubView: View {
    @Binding var spreadsheets: [SavedSpreadsheet]
    @Binding var geminiChatWidth: CGFloat
    @Binding var isDraggingGeminiPanel: Bool
    @Binding var dragStartWidth: CGFloat
    @Binding var cachedGeometryWidth: CGFloat
    @Binding var selectedSpreadsheetForText: SavedSpreadsheet?
    
    let spreadsheetExporter: SpreadsheetExporter
    let geminiCredentialManager: GeminiCredentialManager
    let minChatWidth: CGFloat
    let maxChatWidth: CGFloat
    let formatDate: (Date) -> String
    let onBack: () -> Void
    let onRefresh: () -> Void
    let onSelectForText: (SavedSpreadsheet) -> Void
    let onDelete: (SavedSpreadsheet) -> Void
    
    var selectedSpreadsheetsForGemini: [SavedSpreadsheet] {
        spreadsheets.filter { $0.isSelectedForLLM }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                // Modern Header
                HStack(spacing: 16) {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13))
                            Text("Back")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text("Ask Gemini!")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Horizontal split: Spreadsheet list on left (flexible), Gemini chat pinned to right (fixed width)
                HStack(spacing: 0) {
                    // Left side: List of spreadsheets
                    SpreadsheetListView(
                        spreadsheets: $spreadsheets,
                        spreadsheetExporter: spreadsheetExporter,
                        onSelectForText: onSelectForText,
                        onDelete: onDelete,
                        formatDate: formatDate,
                        isDragging: isDraggingGeminiPanel
                    )
                    
                    // Resizable Vertical Divider
                    ResizableDividerView(
                        isDragging: $isDraggingGeminiPanel,
                        dragStartWidth: $dragStartWidth,
                        currentWidth: geminiChatWidth,
                        geometryWidth: cachedGeometryWidth > 0 ? cachedGeometryWidth : geometry.size.width,
                        minWidth: minChatWidth,
                        maxWidth: maxChatWidth,
                        onWidthChanged: { newWidth in
                            geminiChatWidth = newWidth
                        },
                        onDragEnded: {
                            // Drag ended, no additional action needed
                        }
                    )
                    
                    // Right side: Gemini Chat Window
                    GeminiChatView(
                        selectedSpreadsheets: selectedSpreadsheetsForGemini,
                        geminiAPIKey: Binding(
                            get: { geminiCredentialManager.apiKey },
                            set: { geminiCredentialManager.apiKey = $0 }
                        )
                    )
                    .frame(
                        width: max(minChatWidth, geminiChatWidth > 0 ? geminiChatWidth : (cachedGeometryWidth > 0 ? cachedGeometryWidth * 0.4 : geometry.size.width * 0.4)),
                        alignment: .trailing
                    )
                    .layoutPriority(isDraggingGeminiPanel ? 2 : 1)
                    .transaction { transaction in
                        if isDraggingGeminiPanel {
                            transaction.disablesAnimations = true
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                // Initialize to 40% of screen width if not already set
                cachedGeometryWidth = geometry.size.width
                if geminiChatWidth == 0 {
                    geminiChatWidth = geometry.size.width * 0.4
                }
            }
            .onChange(of: geometry.size.width) { _, newWidth in
                // Cache geometry width when window is resized (but not during drag)
                if !isDraggingGeminiPanel {
                    cachedGeometryWidth = newWidth
                    // Update width proportionally if width hasn't been manually set
                    if geminiChatWidth == 0 {
                        geminiChatWidth = newWidth * 0.4
                    }
                }
            }
        }
    }
}
