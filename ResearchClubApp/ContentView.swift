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
    @State private var useMockData: Bool = true
    @State private var canvasItems: [CanvasItem] = []
    @State private var nextItemPosition: CGPoint = CGPoint(x: 400, y: 300)
    @State private var isCanvasMode: Bool = false
    @State private var searchQueries: [SearchQuery] = []
    @State private var selectedQuery: SearchQuery?
    @State private var savedSpreadsheets: [SavedSpreadsheet] = []
    @State private var showDataAnalysisHub: Bool = false
    @State private var selectedSpreadsheetForText: SavedSpreadsheet?
    @StateObject private var geminiCredentialManager = GeminiCredentialManager()
    @State private var geminiChatHeight: CGFloat = 300
    
    private let spreadsheetExporter = SpreadsheetExporter()
    private let minChatHeight: CGFloat = 200
    private let maxChatHeight: CGFloat = 600
    
    init() {
        // Initialize with mock repository by default
        // Will be updated when credentials are provided
        let repository = MockMassiveRepository()
        _viewModel = StateObject(wrappedValue: StockDataViewModel(repository: repository))
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.doubleColumn)) {
            // Left Sidebar: Input Controls
            sidebarView
                .navigationSplitViewColumnWidth(min: 300, ideal: 350, max: 500)
        } detail: {
            // Right Detail: Canvas View, List View, Data Analysis Hub, or Text View
            if let selectedSpreadsheet = selectedSpreadsheetForText {
                spreadsheetTextView(spreadsheet: selectedSpreadsheet)
            } else if showDataAnalysisHub {
                dataAnalysisHubView
            } else if isCanvasMode {
                CanvasView(items: $canvasItems)
            } else {
                listView
            }
        }
        .onAppear {
            // If credentials were loaded, use real API instead of mock
            if credentialManager.hasValidCredentials && credentialManager.saveCredentials {
                useMockData = false
            }
            // Update repository with current settings
            updateRepository()
            // Load saved spreadsheets immediately
            loadSavedSpreadsheets()
        }
    }
    
    // MARK: - Sidebar View
    
    private var sidebarView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    Text("Stock Data Viewer")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Canvas Mode Toggle
                    Toggle("Canvas Mode", isOn: $isCanvasMode)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Data Analysis Hub Button
                    Button(action: {
                        showDataAnalysisHub = true
                        loadSavedSpreadsheets()
                    }) {
                        HStack {
                            Image(systemName: "chart.bar.doc.horizontal")
                            Text("Data Analysis Hub (\(savedSpreadsheets.count))")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    // Gemini API Key Input (only show in Data Analysis Hub)
                    if showDataAnalysisHub {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gemini API Key")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            SecureField("Enter Gemini API key", text: $geminiCredentialManager.apiKey)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: geminiCredentialManager.apiKey) { _, _ in
                                    if geminiCredentialManager.saveCredentials {
                                        try? geminiCredentialManager.saveCredentialsIfNeeded()
                                    }
                                }
                            
                            Toggle("Save Gemini API key securely", isOn: $geminiCredentialManager.saveCredentials)
                                .onChange(of: geminiCredentialManager.saveCredentials) { _, newValue in
                                    if newValue {
                                        try? geminiCredentialManager.saveCredentialsIfNeeded()
                                    } else {
                                        geminiCredentialManager.deleteSavedCredentials()
                                    }
                                }
                            
                            Text("Get your free API key at https://aistudio.google.com/apikey")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
                .padding(.top)
                
                // Credentials Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("API Credentials")
                        .font(.headline)
                    
                    // API Key Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Massive API Key")
                            .font(.subheadline)
                        SecureField("Enter your API key", text: $credentialManager.apiKey)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: credentialManager.apiKey) { _, _ in
                                updateRepository()
                                // Auto-save if checkbox is checked
                                if credentialManager.saveCredentials {
                                    saveCredentials()
                                }
                            }
                    }
                    
                    // Save Credentials Checkbox
                    Toggle("Save credentials securely", isOn: $credentialManager.saveCredentials)
                        .onChange(of: credentialManager.saveCredentials) { _, newValue in
                            if newValue {
                                saveCredentials()
                            } else {
                                credentialManager.deleteSavedCredentials()
                            }
                        }
                    
                    // Use Mock Data Toggle
                    Toggle("Use mock data (for testing)", isOn: $useMockData)
                        .onChange(of: useMockData) { _, _ in
                            updateRepository()
                        }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // Input Section
                VStack(alignment: .leading, spacing: 16) {
                    // Stock Ticker Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Stock Ticker")
                            .font(.headline)
                        TextField("e.g., AAPL", text: $viewModel.ticker)
                            .textFieldStyle(.roundedBorder)
                            .disableAutocorrection(true)
                    }
                    
                    // Start Date Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Date")
                            .font(.headline)
                        DatePicker(
                            "Start Date",
                            selection: $viewModel.startDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                    }
                    
                    // End Date Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("End Date")
                            .font(.headline)
                        DatePicker(
                            "End Date",
                            selection: $viewModel.endDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                    }
                    
                    // Granularity Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Granularity")
                            .font(.headline)
                        Picker("Granularity", selection: $viewModel.granularity) {
                            ForEach(AggregateGranularity.allCases) { granularity in
                                Text(granularity.displayName).tag(granularity)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // Fetch Button
                    Button(action: {
                        Task { @MainActor in
                            await viewModel.fetchStockData()
                            // Handle data based on mode
                            if !viewModel.aggregates.isEmpty {
                                // Always save to XLSX
                                saveToSpreadsheet()
                                
                                if isCanvasMode {
                                    createCanvasItems()
                                } else {
                                    createSearchQuery()
                                }
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                            }
                            Text(viewModel.isLoading ? "Loading..." : "Fetch Stock Data")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.ticker.isEmpty || viewModel.isLoading)
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func updateRepository() {
        let repository: any MassiveRepository
        
        if useMockData {
            repository = MockMassiveRepository()
        } else if let realRepository = credentialManager.createRepository() {
            repository = realRepository
        } else {
            // Fallback to mock if no valid credentials
            repository = MockMassiveRepository()
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
    private func createCanvasItems() {
        let ticker = viewModel.ticker.uppercased()
        let aggregates = viewModel.aggregates
        let granularity = viewModel.granularity
        
        guard !aggregates.isEmpty else {
            print("⚠️ No aggregates to display")
            return
        }
        
        print("📊 Creating canvas items for \(ticker) with \(aggregates.count) aggregates")
        
        // Create a stock data view item
        let dataItem = CanvasItem(
            position: nextItemPosition,
            size: CGSize(width: 700, height: 600),
            title: "\(ticker) Data - \(granularity.displayName)",
            content: .stockData(aggregates: aggregates, ticker: ticker, granularity: granularity),
            zIndex: canvasItems.count
        )
        
        // Create a chart item positioned next to the data item
        let chartItem = CanvasItem(
            position: CGPoint(x: nextItemPosition.x + 750, y: nextItemPosition.y),
            size: CGSize(width: 800, height: 500),
            title: "\(ticker) Chart - \(granularity.displayName)",
            content: .chart(aggregates: aggregates, ticker: ticker, chartType: .candlestick),
            zIndex: canvasItems.count + 1
        )
        
        withAnimation(.easeOut(duration: 0.3)) {
            canvasItems.append(dataItem)
            canvasItems.append(chartItem)
        }
        
        print("✅ Created \(canvasItems.count) canvas items")
        
        // Update next position for future items (stagger them)
        nextItemPosition = CGPoint(
            x: nextItemPosition.x + 100,
            y: nextItemPosition.y + 100
        )
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
            aggregates: aggregates
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
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Search History")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                if !searchQueries.isEmpty {
                    Button(action: {
                        withAnimation {
                            searchQueries.removeAll()
                        }
                    }) {
                        Text("Clear All")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // List of queries
            if searchQueries.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No Searches Yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Enter a stock ticker and click 'Fetch Stock Data' to begin")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(searchQueries) { query in
                    Button(action: {
                        withAnimation {
                            selectedQuery = query
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(query.displayName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("\(query.aggregates.count) data points")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var queryDetailView: some View {
        Group {
            if let query = selectedQuery {
                VStack(spacing: 0) {
                    // Header with back button
                    HStack {
                        Button(action: {
                            withAnimation {
                                selectedQuery = nil
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Text(query.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // Placeholder for alignment
                        Color.clear
                            .frame(width: 80)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    
                    Divider()
                    
                    // Data view
                    StockDataResultsView(
                        aggregates: query.aggregates,
                        ticker: query.ticker
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                searchQueriesListView
            }
        }
    }
    
    // MARK: - Data Analysis Hub View
    
    private var dataAnalysisHubView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    showDataAnalysisHub = false
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Text("Data Analysis Hub")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    loadSavedSpreadsheets()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // List of spreadsheets (scrollable)
            if savedSpreadsheets.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No Data Available")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Fetched stock data will be automatically saved and available for analysis")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach($savedSpreadsheets) { $spreadsheet in
                        HStack {
                            // LLM Selection Checkbox
                            Toggle("", isOn: Binding(
                                get: { spreadsheet.isSelectedForLLM },
                                set: { newValue in
                                    spreadsheet.isSelectedForLLM = newValue
                                    spreadsheetExporter.updateLLMSelection(for: spreadsheet, isSelected: newValue)
                                }
                            ))
                            .toggleStyle(.checkbox)
                            .help("Include in LLM analysis")
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(spreadsheet.displayName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                HStack(spacing: 12) {
                                    Text("\(spreadsheet.dataPointCount) data points")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Text(formatDate(spreadsheet.createdAt))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            
                            // View as Text button
                            Button(action: {
                                selectedSpreadsheetForText = spreadsheet
                            }) {
                                Image(systemName: "text.alignleft")
                            }
                            .buttonStyle(.bordered)
                            .help("View as Text")
                            
                            // Open in Finder button
                            Button(action: {
                                NSWorkspace.shared.activateFileViewerSelecting([spreadsheet.fileURL])
                            }) {
                                Image(systemName: "folder")
                            }
                            .buttonStyle(.bordered)
                            .help("Show in Finder")
                            
                            // Delete button
                            Button(action: {
                                deleteSpreadsheet(spreadsheet)
                            }) {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                            .help("Delete")
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Resizable Divider
            Divider()
                .background(Color(NSColor.separatorColor))
                .frame(height: 4)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let delta = -value.translation.height // Negative because dragging up increases height
                            let newHeight = geminiChatHeight + delta
                            geminiChatHeight = max(minChatHeight, min(maxChatHeight, newHeight))
                        }
                )
                .onHover { isHovering in
                    if isHovering {
                        NSCursor.resizeUpDown.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            
            // Gemini Chat Window (resizable height)
            GeminiChatView(
                selectedSpreadsheets: selectedSpreadsheetsForGemini,
                geminiAPIKey: $geminiCredentialManager.apiKey
            )
            .frame(height: geminiChatHeight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadSavedSpreadsheets()
        }
    }
    
    private var selectedSpreadsheetsForGemini: [SavedSpreadsheet] {
        savedSpreadsheets.filter { $0.isSelectedForLLM }
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
    
    // MARK: - Spreadsheet Text View
    
    @ViewBuilder
    private func spreadsheetTextView(spreadsheet: SavedSpreadsheet) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    selectedSpreadsheetForText = nil
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Text("\(spreadsheet.displayName) - Text View")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Copy button
                Button(action: {
                    copySpreadsheetToClipboard(spreadsheet)
                }) {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .help("Copy to Clipboard")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Text content
            ScrollView {
                Text(loadSpreadsheetText(spreadsheet: spreadsheet))
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
