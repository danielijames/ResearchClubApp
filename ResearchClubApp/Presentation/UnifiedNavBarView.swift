//
//  UnifiedNavBarView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI

struct UnifiedNavBarView: View {
    let showDataAnalysisHub: Bool
    let showBackButton: Bool
    let isSidebarCollapsed: Bool
    let onBack: (() -> Void)?
    let onToggleDataAnalysisHub: () -> Void
    let onToggleSidebar: () -> Void
    let onToggleCohorts: (() -> Void)?
    let onRefresh: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 16) {
            // Sidebar toggle button
            Button(action: onToggleSidebar) {
                Image(systemName: isSidebarCollapsed ? "sidebar.right" : "sidebar.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isSidebarCollapsed ? Color.purple.opacity(0.1) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .help(isSidebarCollapsed ? "Show sidebar" : "Hide sidebar")
            
            // Back button (if needed)
            if showBackButton, let onBack = onBack {
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
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                // Cohorts button
                if let onToggleCohorts = onToggleCohorts {
                    Button(action: onToggleCohorts) {
                        Image(systemName: "tray.2")
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Manage Cohorts")
                }
                
                // Ask Gemini! button
                Button(action: onToggleDataAnalysisHub) {
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
                
                // Refresh button (if provided)
                if let onRefresh = onRefresh {
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Color(NSColor.controlBackgroundColor)
                .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
        )
        .overlay(
            // Bottom border
            VStack {
                Spacer()
                Divider()
            }
        )
    }
}
