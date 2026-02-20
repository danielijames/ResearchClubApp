//
//  TabBarView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI

struct TabBarView: View {
    @Binding var tabs: [ResearchTab]
    @Binding var selectedTabId: UUID?
    let onNewTab: () -> Void
    let onCloseTab: (UUID) -> Void
    let onRenameTab: (UUID, String) -> Void
    
    private var searchHistoryTab: ResearchTab? {
        tabs.first { $0.isSearchHistoryTab }
    }
    
    private var researchTabs: [ResearchTab] {
        tabs.filter { !$0.isSearchHistoryTab }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Spacer for settings button (44px button + 8px padding + 8px spacing = 60px)
            Spacer()
                .frame(width: 60)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Search History Tab (pinned, always first)
                    if let searchHistoryTab = searchHistoryTab {
                        TabItemView(
                            tab: searchHistoryTab,
                            isSelected: selectedTabId == searchHistoryTab.id,
                            canClose: false,
                            onSelect: {
                                selectedTabId = searchHistoryTab.id
                            },
                            onClose: {},
                            onRename: { _ in }
                        )
                    }
                    
                    // Research Tabs
                    ForEach(researchTabs) { tab in
                        TabItemView(
                            tab: tab,
                            isSelected: selectedTabId == tab.id,
                            canClose: true,
                            onSelect: {
                                selectedTabId = tab.id
                            },
                            onClose: {
                                onCloseTab(tab.id)
                            },
                            onRename: { newName in
                                onRenameTab(tab.id, newName)
                            }
                        )
                    }
                }
                .padding(.horizontal, 12)
            }
            
            // New Tab Button
            Button(action: onNewTab) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help("New Tab")
            .padding(.trailing, 12)
        }
        .frame(height: 44)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }
}

struct TabItemView: View {
    let tab: ResearchTab
    let isSelected: Bool
    let canClose: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    let onRename: (String) -> Void
    
    @State private var isEditing: Bool = false
    @State private var editedName: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            if isEditing {
                TextField("", text: $editedName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .focused($isFocused)
                    .frame(width: 120)
                    .onSubmit {
                        finishEditing()
                    }
                    .onAppear {
                        editedName = tab.name
                        isFocused = true
                    }
            } else {
                Button(action: onSelect) {
                    Text(tab.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isSelected ? .primary : .secondary)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
                .onTapGesture(count: 2) {
                    startEditing()
                }
            }
            
            if canClose {
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close Tab")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color(NSColor.windowBackgroundColor) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color(NSColor.separatorColor) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing {
                onSelect()
            }
        }
    }
    
    private func startEditing() {
        isEditing = true
        editedName = tab.name
    }
    
    private func finishEditing() {
        isEditing = false
        if !editedName.isEmpty && editedName != tab.name {
            onRename(editedName)
        }
    }
}
