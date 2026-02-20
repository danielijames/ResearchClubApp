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
    @State private var canvasItems: [CanvasItem] = []
    @State private var nextItemPosition: CGPoint = CGPoint(x: 400, y: 300)
    @State private var isCanvasMode: Bool = false
    @State private var searchQueries: [SearchQuery] = []
    @State private var selectedQuery: SearchQuery?
    @State private var savedSpreadsheets: [SavedSpreadsheet] = []
    @State private var showDataAnalysisHub: Bool = false
    @State private var selectedSpreadsheetForText: SavedSpreadsheet?
    @StateObject private var geminiCredentialManager = GeminiCredentialManager()
    @State private var geminiChatWidth: CGFloat = 0 // Will be set to 50% of screen width
    @State private var showSettings = false
    
    private let spreadsheetExporter = SpreadsheetExporter()
    private let minChatWidth: CGFloat = 300
    private let maxChatWidth: CGFloat = 800
    
    init() {
        // Initialize with real repository if credentials are available, otherwise nil
        // Will be updated when credentials are provided
        let repository = CredentialManager().createRepository() ?? MassiveRepositoryImpl(apiKey: "")
        _viewModel = StateObject(wrappedValue: StockDataViewModel(repository: repository))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern Header
            modernHeaderView
            
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
    
    // MARK: - Modern Header
    
    private var modernHeaderView: some View {
        HStack(spacing: 16) {
            // Settings Button (prominent)
            Button(action: {
                showSettings = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Settings")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: 12) {
                Button(action: {
                    showDataAnalysisHub = true
                    loadSavedSpreadsheets()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 13))
                        Text("Analysis Hub")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(showDataAnalysisHub ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(showDataAnalysisHub ? Color.blue : Color.clear)
                    )
                }
                .buttonStyle(.plain)
                
                Toggle("", isOn: $isCanvasMode)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .help("Canvas Mode")
                
                Text("Canvas")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Profile Menu (smaller, on the right)
            ProfileMenuView(showSettings: $showSettings)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Color(NSColor.controlBackgroundColor)
                .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
        )
    }
    
    // MARK: - Sidebar View
    
    private var sidebarView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Modern Input Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Stock Query")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    // Stock Ticker Input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ticker")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        TextField("AAPL", text: $viewModel.ticker)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .padding(10)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                            .disableAutocorrection(true)
                    }
                    
                    // Date Range
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Start Date")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        DatePicker(
                            "",
                            selection: $viewModel.startDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("End Date")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        DatePicker(
                            "",
                            selection: $viewModel.endDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    }
                    
                    // Granularity
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Granularity")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Picker("", selection: $viewModel.granularity) {
                            ForEach(AggregateGranularity.allCases) { granularity in
                                Text(granularity.displayName).tag(granularity)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    
                    // Fetch Stock Data Button
                    Button(action: {
                        Task {
                            await viewModel.fetchStockData()
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
                        HStack(spacing: 8) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            Text(viewModel.isLoading ? "Loading..." : "Fetch Data")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if viewModel.ticker.isEmpty || viewModel.isLoading {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.3))
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                }
                            }
                        )
                        .foregroundColor(viewModel.ticker.isEmpty || viewModel.isLoading ? .secondary : .white)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.ticker.isEmpty || viewModel.isLoading)
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                            Text(errorMessage)
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                .padding(16)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
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
            content: .stockData(aggregates: aggregates, ticker: ticker, granularity: granularity, tickerDetails: viewModel.tickerDetails),
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
        VStack(alignment: .leading, spacing: 0) {
            // Modern Header
            HStack {
                Text("Search History")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                if !searchQueries.isEmpty {
                    Button(action: {
                        withAnimation {
                            searchQueries.removeAll()
                        }
                    }) {
                        Text("Clear All")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // List of queries
            if searchQueries.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("No Searches Yet")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("Enter a ticker and fetch data to get started")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
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
                        HStack(spacing: 12) {
                            // Ticker badge
                            Text(query.ticker.uppercased())
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(query.displayName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                HStack(spacing: 8) {
                                    Text("\(query.aggregates.count) points")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Text(formatDate(query.date))
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
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
                    // Modern Header with back button
                    HStack(spacing: 16) {
                        Button(action: {
                            withAnimation {
                                selectedQuery = nil
                            }
                        }) {
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
                        
                        Text(query.displayName)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Placeholder for alignment
                        Color.clear
                            .frame(width: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(NSColor.controlBackgroundColor))
                    
                    Divider()
                    
                    // Data view
                    StockDataResultsView(
                        aggregates: query.aggregates,
                        ticker: query.ticker,
                        tickerDetails: query.tickerDetails
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
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
            // Modern Header
            HStack(spacing: 16) {
                Button(action: {
                    showDataAnalysisHub = false
                }) {
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
                
                Text("Data Analysis Hub")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    loadSavedSpreadsheets()
                }) {
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
                
                // Horizontal split: Spreadsheet list on left, Gemini chat on right
                HStack(spacing: 0) {
                    // Left side: List of spreadsheets
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
                    
                    // Resizable Vertical Divider
                    Divider()
                        .background(Color(NSColor.separatorColor))
                        .frame(width: 4)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let delta = -value.translation.width // Negative because dragging left increases width
                                    let newWidth = geminiChatWidth + delta
                                    geminiChatWidth = max(minChatWidth, min(maxChatWidth, newWidth))
                                }
                        )
                        .onHover { isHovering in
                            if isHovering {
                                NSCursor.resizeLeftRight.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    
                    // Right side: Gemini Chat Window (starts at 50% of screen width, resizable)
                    GeminiChatView(
                        selectedSpreadsheets: selectedSpreadsheetsForGemini,
                        geminiAPIKey: $geminiCredentialManager.apiKey
                    )
                    .frame(width: geminiChatWidth == 0 ? geometry.size.width * 0.5 : geminiChatWidth)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                loadSavedSpreadsheets()
                // Initialize to 50% of screen width if not already set
                if geminiChatWidth == 0 {
                    geminiChatWidth = geometry.size.width * 0.5
                }
            }
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
