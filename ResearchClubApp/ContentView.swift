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
    @State private var cohorts: [Cohort] = [] // All cohorts
    @StateObject private var geminiCredentialManager = GeminiCredentialManager()
    @State private var geminiChatWidth: CGFloat = 0 // Will be set to 40% of screen width (less prominent)
    @State private var showSettings = false
    @State private var isDraggingGeminiPanel: Bool = false
    @State private var dragStartWidth: CGFloat = 0
    @State private var cachedGeometryWidth: CGFloat = 0
    @State private var isSidebarCollapsed: Bool = false
    @State private var showCohortManager = false
    @State private var showDeletionManager = false
    
    private let spreadsheetExporter = SpreadsheetExporter()
    private let minChatWidth: CGFloat = 500
    private let maxChatWidth: CGFloat = 800
    private let appStateManager = AppStateManager.shared
    
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
                    showDataAnalysisHub: currentTab?.showGeminiChat ?? false,
                    showBackButton: shouldShowBackButton,
                    isSidebarCollapsed: isSidebarCollapsed,
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
                    onToggleSidebar: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSidebarCollapsed.toggle()
                        }
                        saveApplicationState()
                    },
                    onToggleCohorts: {
                        showCohortManager = true
                    },
                    onRefresh: navBarRefreshAction,
                    onDeleteQuery: (currentTab?.isSearchHistoryTab == true && currentTab?.selectedQuery != nil) ? {
                        deleteSelectedQuery()
                    } : nil,
                    onCloseQuery: (currentTab?.isSearchHistoryTab == true && currentTab?.selectedQuery != nil) ? {
                        updateCurrentTab { tab in
                            var updated = tab
                            withAnimation {
                                updated.selectedQuery = nil
                            }
                            return updated
                        }
                    } : nil
                )
                
                // Two-column layout: Input Sidebar | Main Content (or Search History)
                HStack(spacing: 0) {
                    // Left: Input Controls Sidebar
                    if !isSidebarCollapsed {
                        StockQuerySidebarView(
                            viewModel: viewModel,
                            onFetchData: {
                                print("🔵 Fetch Data button tapped")
                                print("   Ticker: \(viewModel.ticker)")
                                print("   Start Date: \(viewModel.startDate)")
                                print("   End Date: \(viewModel.endDate)")
                                print("   Granularity: \(viewModel.granularity.displayName)")
                                Task {
                                    print("🔵 Starting fetchStockData()")
                                    await viewModel.fetchStockData()
                                    print("🔵 fetchStockData() completed")
                                    print("   Aggregates count: \(viewModel.aggregates.count)")
                                    print("   Error message: \(viewModel.errorMessage ?? "none")")
                                    
                                    if !viewModel.aggregates.isEmpty {
                                        print("🔵 Aggregates found, saving to spreadsheet...")
                                        saveToSpreadsheet()
                                        print("🔵 Creating search query...")
                                        createSearchQuery()
                                        print("🔵 Done with save and query creation")
                                    } else {
                                        print("⚠️ No aggregates returned, skipping save")
                                        if let error = viewModel.errorMessage {
                                            print("   Error: \(error)")
                                        }
                                    }
                                }
                            }
                        )
                        .frame(width: 350)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        .overlay(
                            // Right border
                            HStack {
                                Spacer()
                                Divider()
                            }
                        )
                    }
                    
                    // Right: Main Content Area or Search History
                    if currentTab?.isSearchHistoryTab == true {
                        // Show QueryDetailView if a query is selected, otherwise show the list
                        if let selectedQuery = currentTab?.selectedQuery {
                            QueryDetailView(query: selectedQuery)
                                .frame(maxWidth: .infinity)
                                .id("queryDetail-\(selectedQuery.id.uuidString)")
                        } else {
                            let searchHistoryQueries = tabs.first(where: { $0.isSearchHistoryTab })?.searchQueries ?? []
                            let _ = print("🔍 Rendering Search History view - queries count: \(searchHistoryQueries.count), tab selected: \(selectedTabId?.uuidString ?? "nil")")
                            SearchQueriesListView(
                                searchQueries: searchHistoryQueries,
                                onSelectQuery: { query in
                                    // Select the query in the search history tab
                                    guard let searchHistoryTabIndex = tabs.firstIndex(where: { $0.isSearchHistoryTab }) else { return }
                                    updateCurrentTab { currentTab in
                                        var updated = currentTab
                                        withAnimation {
                                            updated.selectedQuery = query
                                        }
                                        return updated
                                    }
                                },
                                onClearAll: {
                                    // Clear all queries from Search History tab
                                    guard let searchHistoryTabIndex = tabs.firstIndex(where: { $0.isSearchHistoryTab }) else { return }
                                    var updatedTabs = tabs
                                    updatedTabs[searchHistoryTabIndex].searchQueries.removeAll()
                                    updatedTabs[searchHistoryTabIndex].selectedQuery = nil
                                    tabs = updatedTabs
                                    saveApplicationState() // Save after clearing
                                },
                                formatDate: self.formatDate
                            )
                            .frame(maxWidth: .infinity)
                            .id("searchHistory-\(searchHistoryQueries.count)-\(searchHistoryQueries.map { $0.id.uuidString }.joined(separator: "-"))")
                        }
                    } else {
                        mainContentView
                            .frame(maxWidth: .infinity)
                            .id("\(currentTab?.id.uuidString ?? "")-\(currentTab?.showGeminiChat ?? false)")
                    }
                }
            }
            
            // Settings dropdown menu - fixed 44x44 in top left
            SettingsButtonView(
                showSettings: $showSettings,
                showDeletionManager: $showDeletionManager
            )
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                credentialManager: credentialManager,
                geminiCredentialManager: geminiCredentialManager,
                isPresented: $showSettings,
                onUpdate: {
                    updateRepository()
                },
                cohorts: $cohorts,
                spreadsheets: $savedSpreadsheets,
                spreadsheetExporter: spreadsheetExporter,
                onCohortDeleted: { deletedCohortId in
                    // Remove cohort from all tabs
                    for index in tabs.indices {
                        tabs[index].cohortIds.remove(deletedCohortId)
                    }
                    saveApplicationState()
                },
                onSpreadsheetDeleted: {
                    loadSavedSpreadsheets()
                    saveApplicationState()
                }
            )
        }
        .sheet(isPresented: $showDeletionManager) {
            DeletionManagerView(
                cohorts: $cohorts,
                spreadsheets: $savedSpreadsheets,
                spreadsheetExporter: spreadsheetExporter,
                onCohortDeleted: { deletedCohortId in
                    // Remove cohort from all tabs
                    for index in tabs.indices {
                        tabs[index].cohortIds.remove(deletedCohortId)
                    }
                    saveApplicationState()
                },
                onSpreadsheetDeleted: {
                    loadSavedSpreadsheets()
                    saveApplicationState()
                }
            )
        }
        .onAppear {
            print("🚀 ContentView.onAppear() called")
            // Load saved credentials first
            credentialManager.loadSavedCredentials()
            print("   CredentialManager API key loaded: \(credentialManager.apiKey.isEmpty ? "empty" : "\(credentialManager.apiKey.prefix(8))...")")
            
            // Load application state first
            loadApplicationState()
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
            print("✅ ContentView initialization complete")
        }
        .onChange(of: selectedTabId) { oldValue, newValue in
            // Load messages when switching tabs
            if let tabId = newValue, let index = tabs.firstIndex(where: { $0.id == tabId }) {
                loadMessagesForTab(at: index)
            }
            // Save state when tab changes
            saveApplicationState()
        }
        .onChange(of: tabs) { oldValue, newValue in
            // Save state when tabs change
            saveApplicationState()
        }
        .onChange(of: geminiChatWidth) { oldValue, newValue in
            // Save state when Gemini chat width changes
            saveApplicationState()
        }
        .onChange(of: viewModel.ticker) { oldValue, newValue in
            // Save state when input changes
            saveApplicationState()
        }
        .onChange(of: viewModel.startDate) { oldValue, newValue in
            saveApplicationState()
        }
        .onChange(of: viewModel.endDate) { oldValue, newValue in
            saveApplicationState()
        }
        .onChange(of: viewModel.granularity) { oldValue, newValue in
            saveApplicationState()
        }
        .onChange(of: isSidebarCollapsed) { oldValue, newValue in
            saveApplicationState()
        }
        .onChange(of: cohorts) { oldValue, newValue in
            saveApplicationState()
        }
        .sheet(isPresented: $showCohortManager) {
            CohortManagementView(
                cohorts: $cohorts,
                spreadsheets: savedSpreadsheets,
                currentTab: currentTab,
                onAssignCohortsToTab: { cohortIds in
                    guard let index = currentTabIndex else { return }
                    tabs[index].cohortIds = cohortIds
                    saveApplicationState()
                }
            )
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
        print("🔄 updateRepository() called")
        print("   CredentialManager API key length: \(credentialManager.apiKey.count)")
        print("   CredentialManager API key prefix: \(credentialManager.apiKey.prefix(8))...")
        print("   Has valid credentials: \(credentialManager.hasValidCredentials)")
        
        // Always use real repository - require valid credentials
        guard let repository = credentialManager.createRepository() else {
            print("⚠️ No valid repository created, using empty key repository")
            // If no valid credentials, create repository with empty key (will fail API calls)
            // User must provide credentials in Settings
            let emptyRepository = MassiveRepositoryImpl(apiKey: "")
            viewModel.updateRepository(emptyRepository)
            return
        }
        
        print("✅ Created repository with API key length: \(credentialManager.apiKey.count)")
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
        print("📝 createSearchQuery() called")
        let ticker = viewModel.ticker.uppercased()
        let aggregates = viewModel.aggregates
        let granularity = viewModel.granularity
        // Use startDate as the primary date for display purposes
        let date = viewModel.startDate
        
        print("   Ticker: \(ticker)")
        print("   Aggregates count: \(aggregates.count)")
        print("   Granularity: \(granularity.displayName)")
        print("   Date: \(date)")
        
        guard !aggregates.isEmpty else {
            print("❌ No aggregates to display, cannot create search query")
            return
        }
        
        let query = SearchQuery(
            ticker: ticker,
            date: date,
            granularity: granularity,
            aggregates: aggregates,
            tickerDetails: viewModel.tickerDetails
        )
        
        print("✅ Created SearchQuery: \(query.displayName)")
        print("   Query ID: \(query.id)")
        print("   Query aggregates count: \(query.aggregates.count)")
        
        // Add query to Search History tab
        guard let searchHistoryTabIndex = tabs.firstIndex(where: { $0.isSearchHistoryTab }) else {
            print("⚠️ Search History tab not found, creating it")
            // Create search history tab if it doesn't exist
            let searchHistoryTab = ResearchTab(
                id: ResearchTab.searchHistoryTabId,
                name: "Search History",
                isSearchHistoryTab: true
            )
            tabs.insert(searchHistoryTab, at: 0)
            // Try again with the new tab
            guard let newIndex = tabs.firstIndex(where: { $0.isSearchHistoryTab }) else {
                print("❌ Failed to create Search History tab")
                return
            }
            var updatedTabs = tabs
            var updatedSearchHistoryTab = updatedTabs[newIndex]
            updatedSearchHistoryTab.searchQueries.insert(query, at: 0)
            updatedTabs[newIndex] = updatedSearchHistoryTab
            
            // Update tabs array to trigger SwiftUI update
            withAnimation {
                tabs = updatedTabs
            }
            
            // Automatically switch to Search History tab
            withAnimation {
                selectedTabId = ResearchTab.searchHistoryTabId
            }
            
            saveApplicationState()
            print("✅ Created search query: \(query.displayName) and switched to Search History (tab created)")
            print("   Search History now has \(updatedSearchHistoryTab.searchQueries.count) queries")
            return
        }
        
        print("   Found Search History tab at index: \(searchHistoryTabIndex)")
        print("   Current queries in tab: \(tabs[searchHistoryTabIndex].searchQueries.count)")
        
        var updatedTabs = tabs
        var updatedSearchHistoryTab = updatedTabs[searchHistoryTabIndex]
        updatedSearchHistoryTab.searchQueries.insert(query, at: 0)
        updatedTabs[searchHistoryTabIndex] = updatedSearchHistoryTab
        
        print("   After insert, queries count: \(updatedSearchHistoryTab.searchQueries.count)")
        
        // Update tabs array to trigger SwiftUI update
        withAnimation {
            tabs = updatedTabs
        }
        
        // Automatically switch to Search History tab
        withAnimation {
            selectedTabId = ResearchTab.searchHistoryTabId
        }
        
        saveApplicationState() // Save immediately after adding query
        
        print("✅ Created search query: \(query.displayName) and switched to Search History")
        print("   Search History now has \(updatedSearchHistoryTab.searchQueries.count) queries")
        print("   Current tab ID: \(selectedTabId?.uuidString ?? "nil")")
        print("   Search History tab ID: \(ResearchTab.searchHistoryTabId.uuidString)")
        
        // Verify the query is actually in the tab
        if let finalTab = tabs.first(where: { $0.isSearchHistoryTab }) {
            print("   Verification: Search History tab has \(finalTab.searchQueries.count) queries")
            if finalTab.searchQueries.contains(where: { $0.id == query.id }) {
                print("   ✅ Query is confirmed in Search History tab")
            } else {
                print("   ❌ ERROR: Query is NOT in Search History tab!")
            }
        }
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
    
    // MARK: - Application State Persistence
    
    private func saveApplicationState() {
        let inputState = InputState(
            ticker: viewModel.ticker,
            startDate: viewModel.startDate,
            endDate: viewModel.endDate,
            granularityRawValue: viewModel.granularity.rawValue
        )
        
        let appState = AppState(
            selectedTabId: selectedTabId,
            tabs: tabs,
            cohorts: cohorts,
            inputState: inputState,
            geminiChatWidth: geminiChatWidth,
            isSidebarCollapsed: isSidebarCollapsed,
            lastSavedAt: Date()
        )
        
        appStateManager.saveState(appState)
    }
    
    private func loadApplicationState() {
        guard let savedState = appStateManager.loadState() else {
            print("ℹ️ No saved state found, using defaults")
            return
        }
        
        // Restore tabs
        if !savedState.tabs.isEmpty {
            tabs = savedState.tabs
            
            // Ensure search history tab exists (for backward compatibility)
            if !tabs.contains(where: { $0.isSearchHistoryTab }) {
                let searchHistoryTab = ResearchTab(
                    id: ResearchTab.searchHistoryTabId,
                    name: "Search History",
                    isSearchHistoryTab: true
                )
                tabs.insert(searchHistoryTab, at: 0)
            }
        }
        
        // Restore selected tab
        if let savedTabId = savedState.selectedTabId,
           tabs.contains(where: { $0.id == savedTabId }) {
            selectedTabId = savedTabId
        }
        
        // Restore input state
        viewModel.ticker = savedState.inputState.ticker
        viewModel.startDate = savedState.inputState.startDate
        viewModel.endDate = savedState.inputState.endDate
        viewModel.granularity = savedState.inputState.granularity
        
        // Restore Gemini chat width
        if savedState.geminiChatWidth > 0 {
            geminiChatWidth = savedState.geminiChatWidth
        }
        
        // Restore sidebar collapsed state
        isSidebarCollapsed = savedState.isSidebarCollapsed
        
        // Restore cohorts
        cohorts = savedState.cohorts
        
        print("✅ Restored application state from \(savedState.lastSavedAt)")
        if let searchHistoryTab = tabs.first(where: { $0.isSearchHistoryTab }) {
            print("✅ Restored \(tabs.count) tabs with \(searchHistoryTab.searchQueries.count) search queries in Search History")
        } else {
            print("✅ Restored \(tabs.count) tabs")
        }
    }
    
    // MARK: - Search History View
    
    @MainActor
    private func deleteSelectedQuery() {
        guard let query = currentTab?.selectedQuery,
              let searchHistoryTabIndex = tabs.firstIndex(where: { $0.isSearchHistoryTab }) else {
            return
        }
        
        var updatedTabs = tabs
        updatedTabs[searchHistoryTabIndex].searchQueries.removeAll { $0.id == query.id }
        updatedTabs[searchHistoryTabIndex].selectedQuery = nil
        tabs = updatedTabs
        saveApplicationState()
    }
    
    private var searchHistoryView: some View {
        let queries = searchHistoryTab?.searchQueries ?? []
        let _ = print("🔍 searchHistoryView computed - queries count: \(queries.count)")
        return SearchQueriesListView(
            searchQueries: queries,
            onSelectQuery: { query in
                // Select the query in the search history tab
                guard let searchHistoryTabIndex = tabs.firstIndex(where: { $0.isSearchHistoryTab }) else { return }
                updateCurrentTab { currentTab in
                    var updated = currentTab
                    withAnimation {
                        updated.selectedQuery = query
                    }
                    return updated
                }
            },
            onClearAll: {
                // Clear all queries from Search History tab
                guard let searchHistoryTabIndex = tabs.firstIndex(where: { $0.isSearchHistoryTab }) else { return }
                var updatedTabs = tabs
                updatedTabs[searchHistoryTabIndex].searchQueries.removeAll()
                updatedTabs[searchHistoryTabIndex].selectedQuery = nil
                tabs = updatedTabs
                saveApplicationState() // Save after clearing
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
        // Don't show back button in Search History tab - use action buttons instead
        if currentTab?.isSearchHistoryTab == true {
            return false
        }
        return currentTab?.selectedQuery != nil || currentTab?.selectedSpreadsheetForText != nil
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
            ZStack(alignment: .trailing) {
                // Main content area - takes full width but respects Gemini panel
                contentArea
                    .frame(maxWidth: .infinity)
                    .padding(.trailing, currentTab?.showGeminiChat == true ? 
                        max(minChatWidth, geminiChatWidth > 0 ? geminiChatWidth : (cachedGeometryWidth > 0 ? cachedGeometryWidth * 0.4 : geometry.size.width * 0.4)) + 12 : 0)
                
                // Gemini Chat Panel (when enabled) - anchored to right edge
                if currentTab?.showGeminiChat == true {
                    HStack(spacing: 0) {
                        // Resizable divider on the left
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
                        
                        // Gemini panel - fixed to right edge
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
                            width: max(minChatWidth, geminiChatWidth > 0 ? geminiChatWidth : (cachedGeometryWidth > 0 ? cachedGeometryWidth * 0.4 : geometry.size.width * 0.4))
                        )
                        .layoutPriority(isDraggingGeminiPanel ? 2 : 1)
                        .transaction { transaction in
                            if isDraggingGeminiPanel {
                                transaction.disablesAnimations = true
                            }
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
                    spreadsheets: Binding(
                        get: { currentTab?.spreadsheets ?? [] },
                        set: { newValue in
                            guard let index = currentTabIndex else { return }
                            tabs[index].spreadsheets = newValue
                        }
                    ),
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
                    selectedCohortIds: Binding(
                        get: { currentTab?.selectedCohortIds ?? [] },
                        set: { newValue in
                            guard let index = currentTabIndex else { return }
                            tabs[index].selectedCohortIds = newValue
                            saveApplicationState()
                        }
                    ),
                    cohorts: cohorts,
                    currentTabCohortIds: currentTab?.cohortIds ?? [],
                    spreadsheetExporter: spreadsheetExporter,
                    formatDate: formatDate,
                    allSpreadsheets: savedSpreadsheets,
                    onSelectForText: { spreadsheet in
                        updateCurrentTab { tab in
                            var updated = tab
                            updated.selectedSpreadsheetForText = spreadsheet
                            return updated
                        }
                    },
                    onAddSpreadsheetToTab: { spreadsheetId in
                        guard let index = currentTabIndex else { return }
                        tabs[index].selectedSpreadsheetIds.insert(spreadsheetId)
                        // Also add to spreadsheets list if not already there
                        if !tabs[index].spreadsheets.contains(where: { $0.id == spreadsheetId }) {
                            if let spreadsheet = savedSpreadsheets.first(where: { $0.id == spreadsheetId }) {
                                tabs[index].spreadsheets.append(spreadsheet)
                            }
                        }
                        saveApplicationState()
                    },
                    onShowCohortManager: {
                        showCohortManager = true
                    },
                    onRemoveFromTab: { spreadsheetIds in
                        guard let index = currentTabIndex else { return }
                        // Remove from tab's selectedSpreadsheetIds and spreadsheets list
                        tabs[index].selectedSpreadsheetIds.subtract(spreadsheetIds)
                        tabs[index].spreadsheets.removeAll { spreadsheetIds.contains($0.id) }
                        saveApplicationState()
                    },
                    onAddCohortToTab: { cohortId in
                        guard let index = currentTabIndex else { return }
                        tabs[index].cohortIds.insert(cohortId)
                        saveApplicationState()
                    },
                    onRemoveCohortFromTab: { cohortId in
                        guard let index = currentTabIndex else { return }
                        tabs[index].cohortIds.remove(cohortId)
                        saveApplicationState()
                    }
                )
            }
        }
    }
    
    private var selectedSpreadsheetsForGemini: [SavedSpreadsheet] {
        guard let currentTab = currentTab else { return [] }
        
        // Start with directly selected spreadsheets
        var spreadsheetIds = currentTab.selectedSpreadsheetIds
        
        // Add all spreadsheets from selected cohorts
        let selectedCohorts = cohorts.filter { currentTab.selectedCohortIds.contains($0.id) }
        for cohort in selectedCohorts {
            spreadsheetIds.formUnion(cohort.spreadsheetIds)
        }
        
        // Return unique spreadsheets (in case a spreadsheet is both directly selected and in a cohort)
        let uniqueIds = Array(spreadsheetIds)
        return savedSpreadsheets.filter { uniqueIds.contains($0.id) }
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
