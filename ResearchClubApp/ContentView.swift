//
//  ContentView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var credentialManager = CredentialManager()
    @StateObject private var viewModel: StockDataViewModel
    @State private var tabs: [ResearchTab] = [
        ResearchTab(id: ResearchTab.searchHistoryTabId, name: "Search History", isSearchHistoryTab: true),
        ResearchTab(name: "Research 1", showGeminiChat: false)
    ]
    @State private var selectedTabId: UUID?
    
    private var searchHistoryTab: ResearchTab? {
        tabs.first { $0.isSearchHistoryTab }
    }
    
    private var allSearchQueries: [SearchQuery] {
        tabs.filter { !$0.isSearchHistoryTab }.flatMap { $0.searchQueries }
    }
    @State private var savedSpreadsheets: [SavedSpreadsheet] = [] // Shared across all tabs
    @StateObject private var geminiCredentialManager = GeminiCredentialManager()
    @State private var geminiChatWidth: CGFloat = 0 // Will be set to 40% of screen width (less prominent)
    @State private var showSettings = false
    @State private var isDraggingGeminiPanel: Bool = false
    @State private var dragStartWidth: CGFloat = 0
    @State private var cachedGeometryWidth: CGFloat = 0
    
    private let spreadsheetExporter = SpreadsheetExporter()
    private let minChatWidth: CGFloat = 500
    private let maxChatWidth: CGFloat = 800
    
    private var currentTab: ResearchTab? {
        tabs.first { $0.id == selectedTabId } ?? tabs.first
    }
    
    private var currentTabIndex: Int? {
        tabs.firstIndex { $0.id == selectedTabId } ?? tabs.firstIndex { $0.id == tabs.first?.id }
    }
    
    init() {
        // Initialize with real repository if credentials are available, otherwise nil
        // Will be updated when credentials are provided
        let repository = CredentialManager().createRepository() ?? MassiveRepositoryImpl(apiKey: "")
        _viewModel = StateObject(wrappedValue: StockDataViewModel(repository: repository))
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                // Tab Bar
                TabBarView(
                    tabs: $tabs,
                    selectedTabId: $selectedTabId,
                    onNewTab: createNewTab,
                    onCloseTab: closeTab,
                    onRenameTab: renameTab
                )
                
                // Unified Navigation Bar
                UnifiedNavBarView(
                    title: navBarTitle,
                    showDataAnalysisHub: currentTab?.showGeminiChat ?? false,
                    showBackButton: shouldShowBackButton,
                    onBack: navBarBackAction,
                    onToggleDataAnalysisHub: {
                        guard let index = currentTabIndex else { return }
                        var updatedTabs = tabs
                        updatedTabs[index].showGeminiChat.toggle()
                        let shouldLoadSpreadsheets = updatedTabs[index].showGeminiChat
                        tabs = updatedTabs
                        if shouldLoadSpreadsheets {
                            loadSavedSpreadsheets()
                        }
                    },
                    onRefresh: navBarRefreshAction
                )
                
                // Two-column layout: Input Sidebar | Main Content (or Search History)
                HStack(spacing: 0) {
                    // Left: Input Controls Sidebar
                    StockQuerySidebarView(
                        viewModel: viewModel,
                        onFetchData: {
                            Task {
                                await viewModel.fetchStockData()
                                if !viewModel.aggregates.isEmpty {
                                    saveToSpreadsheet()
                                    createSearchQuery()
                                }
                            }
                        }
                    )
                    .frame(width: 350)
                    
                    Divider()
                    
                    // Right: Main Content Area or Search History
                    if currentTab?.isSearchHistoryTab == true {
                        searchHistoryView
                            .frame(maxWidth: .infinity)
                    } else {
                        mainContentView
                            .frame(maxWidth: .infinity)
                            .id("\(currentTab?.id.uuidString ?? "")-\(currentTab?.showGeminiChat ?? false)")
                    }
                }
            }
            
            // Settings dropdown menu - fixed 44x44 in top left
            SettingsButtonView(showSettings: $showSettings)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                credentialManager: credentialManager,
                geminiCredentialManager: geminiCredentialManager,
                isPresented: $showSettings,
                onUpdate: {
                    updateRepository()
                }
            )
        }
        .onAppear {
            // Update repository with current settings
            updateRepository()
            // Load saved spreadsheets immediately
            loadSavedSpreadsheets()
            // Load messages for all tabs
            loadMessagesForAllTabs()
            // Set initial selected tab (prefer first research tab, fallback to search history)
            if selectedTabId == nil {
                if let firstResearchTab = tabs.first(where: { !$0.isSearchHistoryTab }) {
                    selectedTabId = firstResearchTab.id
                } else if let searchHistoryTab = tabs.first(where: { $0.isSearchHistoryTab }) {
                    selectedTabId = searchHistoryTab.id
                }
            }
        }
        .onChange(of: selectedTabId) { oldValue, newValue in
            // Load messages when switching tabs
            if let tabId = newValue, let index = tabs.firstIndex(where: { $0.id == tabId }) {
                loadMessagesForTab(at: index)
            }
        }
    }
    
    // MARK: - Tab Management
    
    private func createNewTab() {
        let researchTabCount = tabs.filter { !$0.isSearchHistoryTab }.count
        let newTab = ResearchTab(name: "Research \(researchTabCount + 1)")
        tabs.append(newTab)
        selectedTabId = newTab.id
    }
    
    private func closeTab(_ tabId: UUID) {
        // Don't allow closing the Search History tab
        guard let tab = tabs.first(where: { $0.id == tabId }),
              !tab.isSearchHistoryTab else { return }
        
        // Don't close if it's the last research tab
        let researchTabs = tabs.filter { !$0.isSearchHistoryTab }
        guard researchTabs.count > 1 else { return }
        
        tabs.removeAll { $0.id == tabId }
        
        // If we closed the selected tab, select another one
        if selectedTabId == tabId {
            selectedTabId = tabs.first?.id
        }
    }
    
    private func renameTab(_ tabId: UUID, _ newName: String) {
        guard let index = tabs.firstIndex(where: { $0.id == tabId }) else { return }
        tabs[index].name = newName
    }
    
    private func updateCurrentTab(_ update: (ResearchTab) -> ResearchTab) {
        guard let index = currentTabIndex, let tab = currentTab else { return }
        tabs[index] = update(tab)
    }
    
    
    private func updateRepository() {
        // Always use real repository - require valid credentials
        guard let repository = credentialManager.createRepository() else {
            // If no valid credentials, create repository with empty key (will fail API calls)
            // User must provide credentials in Settings
            let emptyRepository = MassiveRepositoryImpl(apiKey: "")
            viewModel.updateRepository(emptyRepository)
            return
        }
        
        // Update the existing ViewModel's repository
        viewModel.updateRepository(repository)
    }
    
    private func saveCredentials() {
        do {
            try credentialManager.saveCredentialsIfNeeded()
        } catch {
            // Handle error - could show alert to user
            print("Failed to save credentials: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func createSearchQuery() {
        let ticker = viewModel.ticker.uppercased()
        let aggregates = viewModel.aggregates
        let granularity = viewModel.granularity
        // Use startDate as the primary date for display purposes
        let date = viewModel.startDate
        
        guard !aggregates.isEmpty else {
            print("⚠️ No aggregates to display")
            return
        }
        
        let query = SearchQuery(
            ticker: ticker,
            date: date,
            granularity: granularity,
            aggregates: aggregates,
            tickerDetails: viewModel.tickerDetails
        )
        
        // Add query to current research tab (not search history tab)
        if let index = currentTabIndex, let tab = currentTab, !tab.isSearchHistoryTab {
            tabs[index].searchQueries.insert(query, at: 0)
        } else {
            // If we're on search history tab or no tab selected, add to first research tab
            if let firstResearchTabIndex = tabs.firstIndex(where: { !$0.isSearchHistoryTab }) {
                tabs[firstResearchTabIndex].searchQueries.insert(query, at: 0)
            }
        }
        
        print("✅ Created search query: \(query.displayName)")
    }
    
    @MainActor
    private func saveToSpreadsheet() {
        let ticker = viewModel.ticker.uppercased()
        let aggregates = viewModel.aggregates
        let granularity = viewModel.granularity
        // Use startDate as the primary date for spreadsheet naming/display
        let date = viewModel.startDate
        
        guard !aggregates.isEmpty else {
            print("⚠️ No aggregates to save")
            return
        }
        
        do {
            let savedSpreadsheet = try spreadsheetExporter.exportToXLSX(
                aggregates: aggregates,
                ticker: ticker,
                date: date,
                granularity: granularity
            )
            
            // Add to saved spreadsheets list
            savedSpreadsheets.insert(savedSpreadsheet, at: 0)
            
            print("✅ Saved spreadsheet: \(savedSpreadsheet.fileName)")
        } catch {
            print("❌ Failed to save spreadsheet: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Message Persistence
    
    private func loadMessagesForAllTabs() {
        for index in tabs.indices {
            loadMessagesForTab(at: index)
        }
    }
    
    private func loadMessagesForTab(at index: Int) {
        let tab = tabs[index]
        let storageKey = "gemini_conversation_\(tab.id.uuidString)"
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            tabs[index].geminiMessages = decoded
        }
    }
    
    private func saveMessagesForTab(at index: Int) {
        let tab = tabs[index]
        let storageKey = "gemini_conversation_\(tab.id.uuidString)"
        if let encoded = try? JSONEncoder().encode(tab.geminiMessages) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadSavedSpreadsheets() {
        savedSpreadsheets = spreadsheetExporter.getAllSavedSpreadsheets()
    }
    
    // MARK: - Search History View
    
    private var searchHistoryView: some View {
        SearchQueriesListView(
            searchQueries: allSearchQueries,
            onSelectQuery: { query in
                // Find which tab this query belongs to and switch to it
                if let tab = tabs.first(where: { $0.searchQueries.contains(where: { $0.id == query.id }) }) {
                    selectedTabId = tab.id
                    updateCurrentTab { currentTab in
                        var updated = currentTab
                        withAnimation {
                            updated.selectedQuery = query
                        }
                        return updated
                    }
                }
            },
            onClearAll: {
                // Clear queries from all research tabs
                for index in tabs.indices where !tabs[index].isSearchHistoryTab {
                    tabs[index].searchQueries.removeAll()
                    tabs[index].selectedQuery = nil
                }
            },
            formatDate: self.formatDate
        )
    }
    
    // MARK: - Navigation Bar Helpers
    
    private var navBarTitle: String {
        if currentTab?.isSearchHistoryTab == true {
            return "Search History"
        } else if currentTab?.selectedSpreadsheetForText != nil {
            return "\(currentTab?.selectedSpreadsheetForText?.displayName ?? "") - Text View"
        } else if let query = currentTab?.selectedQuery {
            return query.displayName
        } else {
            return currentTab?.name ?? "Research"
        }
    }
    
    private var shouldShowBackButton: Bool {
        currentTab?.selectedQuery != nil || currentTab?.selectedSpreadsheetForText != nil
    }
    
    private var navBarBackAction: (() -> Void)? {
        if currentTab?.selectedSpreadsheetForText != nil {
            return {
                updateCurrentTab { tab in
                    var updated = tab
                    updated.selectedSpreadsheetForText = nil
                    return updated
                }
            }
        } else if currentTab?.selectedQuery != nil {
            return {
                updateCurrentTab { tab in
                    var updated = tab
                    withAnimation {
                        updated.selectedQuery = nil
                    }
                    return updated
                }
            }
        }
        return nil
    }
    
    private var navBarRefreshAction: (() -> Void)? {
        // Refresh action can be added here if needed
        return nil
    }
    
    // MARK: - Main Content View
    
    private var mainContentView: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Main content area
                contentArea
                    .frame(maxWidth: .infinity)
                
                // Gemini Chat Panel (when enabled)
                if currentTab?.showGeminiChat == true {
                    Divider()
                    
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
                        onDragEnded: {}
                    )
                    
                    GeminiChatView(
                        selectedSpreadsheets: selectedSpreadsheetsForGemini,
                        geminiAPIKey: Binding(
                            get: { geminiCredentialManager.apiKey },
                            set: { geminiCredentialManager.apiKey = $0 }
                        ),
                        messages: Binding(
                            get: { currentTab?.geminiMessages ?? [] },
                            set: { newMessages in
                                guard let index = currentTabIndex else { return }
                                tabs[index].geminiMessages = newMessages
                                saveMessagesForTab(at: index)
                            }
                        ),
                        tabId: currentTab?.id ?? UUID()
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
                    .onAppear {
                        cachedGeometryWidth = geometry.size.width
                        if geminiChatWidth == 0 {
                            geminiChatWidth = geometry.size.width * 0.4
                        }
                    }
                    .onChange(of: geometry.size.width) { _, newWidth in
                        if !isDraggingGeminiPanel {
                            cachedGeometryWidth = newWidth
                            if geminiChatWidth == 0 {
                                geminiChatWidth = newWidth * 0.4
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var contentArea: some View {
        Group {
            if let selectedSpreadsheet = currentTab?.selectedSpreadsheetForText {
                SpreadsheetTextView(
                    spreadsheet: selectedSpreadsheet,
                    onCopy: {
                        copySpreadsheetToClipboard(selectedSpreadsheet)
                    }
                )
            } else if let query = currentTab?.selectedQuery {
                QueryDetailView(query: query)
            } else {
                // Show Data Analysis Hub as default content
                DataAnalysisHubView(
                    spreadsheets: $savedSpreadsheets,
                    selectedSpreadsheetIds: Binding(
                        get: { currentTab?.selectedSpreadsheetIds ?? [] },
                        set: { newValue in
                            guard let index = currentTabIndex else { return }
                            tabs[index].selectedSpreadsheetIds = newValue
                        }
                    ),
                    selectedSpreadsheetForText: Binding(
                        get: { currentTab?.selectedSpreadsheetForText },
                        set: { newValue in
                            updateCurrentTab { tab in
                                var updated = tab
                                updated.selectedSpreadsheetForText = newValue
                                return updated
                            }
                        }
                    ),
                    spreadsheetExporter: spreadsheetExporter,
                    formatDate: formatDate,
                    onRefresh: {
                        loadSavedSpreadsheets()
                    },
                    onSelectForText: { spreadsheet in
                        updateCurrentTab { tab in
                            var updated = tab
                            updated.selectedSpreadsheetForText = spreadsheet
                            return updated
                        }
                    },
                    onDelete: deleteSpreadsheet
                )
            }
        }
    }
    
    private var selectedSpreadsheetsForGemini: [SavedSpreadsheet] {
        guard let currentTab = currentTab else { return [] }
        return savedSpreadsheets.filter { currentTab.selectedSpreadsheetIds.contains($0.id) }
    }
    
    private func deleteSpreadsheet(_ spreadsheet: SavedSpreadsheet) {
        do {
            try spreadsheetExporter.deleteSpreadsheet(spreadsheet)
            withAnimation {
                savedSpreadsheets.removeAll { $0.id == spreadsheet.id }
            }
        } catch {
            print("❌ Failed to delete spreadsheet: \(error.localizedDescription)")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    
    private func loadSpreadsheetText(spreadsheet: SavedSpreadsheet) -> String {
        do {
            let content = try String(contentsOf: spreadsheet.fileURL, encoding: .utf8)
            return content
        } catch {
            return "Error loading file: \(error.localizedDescription)"
        }
    }
    
    private func copySpreadsheetToClipboard(_ spreadsheet: SavedSpreadsheet) {
        let text = loadSpreadsheetText(spreadsheet: spreadsheet)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

#Preview {
    ContentView()
}
