//
//  StockDataResultsView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI
import AppKit

struct StockDataResultsView: View {
    let aggregates: [StockAggregate]
    let ticker: String
    let tickerDetails: TickerDetails?
    
    @State private var sortOrder = [KeyPathComparator(\StockAggregate.timestamp)]
    
    private var granularityDisplay: String {
        guard let firstAggregate = aggregates.first else { return "" }
        let granularity = AggregateGranularity(rawValue: firstAggregate.granularityMinutes)
        return granularity?.displayName ?? "\(firstAggregate.granularityMinutes) minutes"
    }
    
    private var sortedAggregates: [StockAggregate] {
        aggregates.sorted(using: sortOrder)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Stock Data: \(ticker)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("\(aggregates.count) \(granularityDisplay) aggregates")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                // Ticker Details Section
                if let details = tickerDetails {
                    Divider()
                    
                    HStack(spacing: 24) {
                        // Market Cap
                        if let marketCap = details.formattedMarketCap {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Market Cap")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(marketCap)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        // Shares Outstanding (Float)
                        if let sharesOutstanding = details.formattedSharesOutstanding {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Float")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(sharesOutstanding)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        // Weighted Shares Outstanding
                        if let weightedShares = details.formattedWeightedSharesOutstanding {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Weighted Shares")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(weightedShares)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Scrollable Data Table (takes remaining space above chart)
            if aggregates.isEmpty {
                VStack {
                    Spacer()
                    Text("No data available")
                        .foregroundColor(.secondary)
                        .italic()
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Datadog-inspired table with sortable columns
                Table(sortedAggregates, sortOrder: $sortOrder) {
                    TableColumn("Time", value: \.timestamp) { aggregate in
                        Text(formatTime(aggregate.timestamp))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    .width(min: 100, ideal: 120)
                    
                    TableColumn("Open", value: \.open) { aggregate in
                        Text(String(format: "$%.2f", aggregate.open))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                    .width(min: 90, ideal: 100)
                    
                    TableColumn("High", value: \.high) { aggregate in
                        Text(String(format: "$%.2f", aggregate.high))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    .width(min: 90, ideal: 100)
                    
                    TableColumn("Low", value: \.low) { aggregate in
                        Text(String(format: "$%.2f", aggregate.low))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.red)
                    }
                    .width(min: 90, ideal: 100)
                    
                    TableColumn("Close", value: \.close) { aggregate in
                        HStack(spacing: 6) {
                            Text(String(format: "$%.2f", aggregate.close))
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            // Show change indicator compared to open price
                            let change = aggregate.close - aggregate.open
                            let isUp = change >= 0
                            Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption2)
                                .foregroundColor(isUp ? .green : .red)
                        }
                    }
                    .width(min: 110, ideal: 130)
                    
                    TableColumn("Volume", value: \.volume) { aggregate in
                        Text(formatVolume(aggregate.volume))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .width(min: 100, ideal: 120)
                }
                .tableStyle(.inset(alternatesRowBackgrounds: true))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Divider()
            
            // Fixed Chart at Bottom (always visible, independent of scrolling)
            StockChartView(aggregates: aggregates, ticker: ticker)
                .frame(height: 250, alignment: .bottom)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func formatVolume(_ volume: Int64) -> String {
        if volume >= 1_000_000 {
            return String(format: "%.2fM", Double(volume) / 1_000_000.0)
        } else if volume >= 1_000 {
            return String(format: "%.2fK", Double(volume) / 1_000.0)
        } else {
            return "\(volume)"
        }
    }
    
}


#Preview {
    StockDataResultsView(
        aggregates: [
            StockAggregate(
                ticker: "AAPL",
                timestamp: Date(),
                open: 150.0,
                high: 151.5,
                low: 149.8,
                close: 150.5,
                volume: 1000000,
                granularityMinutes: 5
            )
        ],
        ticker: "AAPL",
        tickerDetails: nil
    )
}
