//
//  StockQuerySidebarView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI
import AppKit

struct StockQuerySidebarView: View {
    @ObservedObject var viewModel: StockDataViewModel
    var onFetchData: () -> Void
    
    var body: some View {
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
                        print("🔵 Fetch Data button tapped in StockQuerySidebarView")
                        print("   Ticker: '\(viewModel.ticker)'")
                        print("   Is Loading: \(viewModel.isLoading)")
                        onFetchData()
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
}
