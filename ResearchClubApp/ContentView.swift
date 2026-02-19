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
            // Right Detail: Results View
            detailView
        }
        .onAppear {
            // If credentials were loaded, use real API instead of mock
            if credentialManager.hasValidCredentials && credentialManager.saveCredentials {
                useMockData = false
            }
            // Update repository with current settings
            updateRepository()
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
                    
                    // Date Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
                            .font(.headline)
                        DatePicker(
                            "Select Date",
                            selection: $viewModel.selectedDate,
                            displayedComponents: .date
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
                        Task {
                            await viewModel.fetchStockData()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                            }
                            Text(viewModel.isLoading ? "Loading..." : "Fetch Stock Data")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.ticker.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
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
    
    // MARK: - Detail View
    
    private var detailView: some View {
        Group {
            if viewModel.isLoading {
                // Loading Indicator
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(2.0)
                    Text("Fetching stock data...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    if !viewModel.ticker.isEmpty {
                        Text("Fetching \(viewModel.ticker.uppercased()) data")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !viewModel.aggregates.isEmpty {
                // Results View
                StockDataResultsView(
                    aggregates: viewModel.aggregates,
                    ticker: viewModel.ticker.uppercased()
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Empty State
                VStack(spacing: 20) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No Data")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Enter a stock ticker and click 'Fetch Stock Data' to begin")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
}

#Preview {
    ContentView()
}
