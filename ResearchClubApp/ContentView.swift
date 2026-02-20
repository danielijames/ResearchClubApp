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
    @State private var searchQueries: [SearchQuery] = []
    @State private var selectedQuery: SearchQuery?
    @State private var savedSpreadsheets: [SavedSpreadsheet] = []
    @State private var showDataAnalysisHub: Bool = true // Default to showing Analysis Hub
    @State private var selectedSpreadsheetForText: SavedSpreadsheet?
    @StateObject private var geminiCredentialManager = GeminiCredentialManager()
    @State private var geminiChatWidth: CGFloat = 0 // Will be set to 40% of screen width (less prominent)
    @State private var showSettings = false
    @State private var isDraggingGeminiPanel: Bool = false
    @State private var dragStartWidth: CGFloat = 0
    @State private var cachedGeometryWidth: CGFloat = 0
    
    private let spreadsheetExporter = SpreadsheetExporter()
    private let minChatWidth: CGFloat = 500
    private let maxChatWidth: CGFloat = 800
    
    init() {
        // Initialize with real repository if credentials are available, otherwise nil
        // Will be updated when credentials are provided
        let repository = CredentialManager().createRepository() ?? MassiveRepositoryImpl(apiKey: "")
        _viewModel = StateObject(wrappedValue: StockDataViewModel(repository: repository))
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                // Modern Header
                ModernHeaderView(
                    showDataAnalysisHub: $showDataAnalysisHub,
                    onToggleDataAnalysisHub: {
                        if showDataAnalysisHub {
                            loadSavedSpreadsheets()
                        }
                    }
                )
                
                NavigationSplitView(columnVisibility: .constant(.doubleColumn)) {
                    // Left Sidebar: Input Controls
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
                    .navigationSplitViewColumnWidth(min: 300, ideal: 350, max: 500)
                } detail: {
                    // Right Detail: List View, Data Analysis Hub, or Text View
                    if let selectedSpreadsheet = selectedSpreadsheetForText {
                        SpreadsheetTextView(
                            spreadsheet: selectedSpreadsheet,
                            onBack: {
                                selectedSpreadsheetForText = nil
                            },
                            onCopy: {
                                copySpreadsheetToClipboard(selectedSpreadsheet)
                            }
                        )
                    } else if showDataAnalysisHub {
                        DataAnalysisHubView(
                            spreadsheets: $savedSpreadsheets,
                            geminiChatWidth: $geminiChatWidth,
                            isDraggingGeminiPanel: $isDraggingGeminiPanel,
                            dragStartWidth: $dragStartWidth,
                            cachedGeometryWidth: $cachedGeometryWidth,
                            selectedSpreadsheetForText: $selectedSpreadsheetForText,
                            spreadsheetExporter: spreadsheetExporter,
                            geminiCredentialManager: geminiCredentialManager,
                            minChatWidth: minChatWidth,
                            maxChatWidth: maxChatWidth,
                            formatDate: formatDate,
                            onBack: {
                                showDataAnalysisHub = false
                            },
                            onRefresh: {
                                loadSavedSpreadsheets()
                            },
                            onSelectForText: { spreadsheet in
                                selectedSpreadsheetForText = spreadsheet
                            },
                            onDelete: deleteSpreadsheet
                        )
                    } else {
                        listView
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
        }
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
        
        withAnimation {
            searchQueries.insert(query, at: 0) // Add to beginning
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
    
    private func loadSavedSpreadsheets() {
        savedSpreadsheets = spreadsheetExporter.getAllSavedSpreadsheets()
    }
    
    // MARK: - List View
    
    private var listView: some View {
        Group {
            if selectedQuery == nil {
                // Show list of search queries
                searchQueriesListView
            } else {
                // Show selected query details
                queryDetailView
            }
        }
    }
    
    private var searchQueriesListView: some View {
        SearchQueriesListView(
            searchQueries: searchQueries,
            onSelectQuery: { query in
                withAnimation {
                    selectedQuery = query
                }
            },
            onClearAll: {
                withAnimation {
                    searchQueries.removeAll()
                }
            },
            formatDate: formatDate
        )
    }
    
    private var queryDetailView: some View {
        Group {
            if let query = selectedQuery {
                QueryDetailView(
                    query: query,
                    onBack: {
                        withAnimation {
                            selectedQuery = nil
                        }
                    }
                )
            } else {
                searchQueriesListView
            }
        }
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
