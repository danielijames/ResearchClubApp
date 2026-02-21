//
//  StockChartView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI
import Charts

enum ChartType: String, CaseIterable, Identifiable {
    case candlestick = "Candlestick"
    case line = "Line"
    case dot = "Dot"
    case histogram = "Histogram"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .candlestick: return "Candlestick"
        case .line: return "Line"
        case .dot: return "Dot"
        case .histogram: return "Histogram"
        }
    }
}

struct StockChartView: View {
    let aggregates: [StockAggregate]
    let ticker: String
    
    // Chart type selection
    @State private var chartType: ChartType
    
    init(aggregates: [StockAggregate], ticker: String, initialChartType: ChartType = .line) {
        self.aggregates = aggregates
        self.ticker = ticker
        _chartType = State(initialValue: initialChartType)
    }
    
    // Zoom and pan state
    @State private var visibleXRange: ClosedRange<Date>?
    @State private var visibleYRange: ClosedRange<Double>?
    @State private var lastMagnificationValue: CGFloat = 1.0
    @State private var lastDragValue: CGSize = .zero
    @State private var pinchStartLocation: CGPoint = .zero
    @State private var pinchCurrentLocation: CGPoint = .zero
    @State private var isPinching: Bool = false
    
    private var fullPriceRange: ClosedRange<Double> {
        guard !aggregates.isEmpty else {
            return 0...100
        }
        let minPrice = aggregates.map { $0.low }.min() ?? 0
        let maxPrice = aggregates.map { $0.high }.max() ?? 100
        let padding = (maxPrice - minPrice) * 0.1 // 10% padding
        return (minPrice - padding)...(maxPrice + padding)
    }
    
    private var fullDateRange: ClosedRange<Date> {
        guard !aggregates.isEmpty else {
            return Date()...Date()
        }
        let dates = aggregates.map { $0.timestamp }.sorted()
        return dates.first!...dates.last!
    }
    
    private var visiblePriceRange: ClosedRange<Double> {
        visibleYRange ?? fullPriceRange
    }
    
    private var visibleDateRange: ClosedRange<Date> {
        visibleXRange ?? fullDateRange
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatPrice(_ price: Double) -> String {
        return String(format: "$%.2f", price)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Chart Header with Chart Type Selector and Controls
            HStack {
                Text("Price Chart")
                    .font(.headline)
                
                // Chart Type Picker
                Picker("Chart Type", selection: $chartType) {
                    ForEach(ChartType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
                
                Spacer()
                
                // Zoom Controls
                if isZoomed {
                    Button(action: resetZoom) {
                        Label("Reset Zoom", systemImage: "arrow.counterclockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
                
                if let lastPrice = aggregates.last?.close {
                    Text(String(format: "$%.2f", lastPrice))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Chart
            if aggregates.isEmpty {
                Text("No data to chart")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                chartContent
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .border(Color(NSColor.separatorColor), width: 1)
        .onAppear {
            resetZoom()
        }
    }
    
    // MARK: - Chart Content
    
    @ViewBuilder
    private var chartContent: some View {
        Group {
            switch chartType {
            case .candlestick:
                candlestickChart
            case .line:
                lineChart
            case .dot:
                dotChart
            case .histogram:
                histogramChart
            }
        }
    }
    
    private var candlestickChart: some View {
        Chart(filteredAggregates, id: \.id) { aggregate in
            let isUp = aggregate.close >= aggregate.open
            let bodyTop = max(aggregate.open, aggregate.close)
            let bodyBottom = min(aggregate.open, aggregate.close)
            
            // High wick (from high to body top)
            if aggregate.high > bodyTop {
                RuleMark(
                    x: .value("Time", aggregate.timestamp),
                    yStart: .value("High", aggregate.high),
                    yEnd: .value("Body Top", bodyTop)
                )
                .foregroundStyle(isUp ? Color.green.opacity(0.7) : Color.red.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 1))
            }
            
            // Low wick (from body bottom to low)
            if aggregate.low < bodyBottom {
                RuleMark(
                    x: .value("Time", aggregate.timestamp),
                    yStart: .value("Body Bottom", bodyBottom),
                    yEnd: .value("Low", aggregate.low)
                )
                .foregroundStyle(isUp ? Color.green.opacity(0.7) : Color.red.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 1))
            }
            
            // Candlestick body (filled rectangle)
            RectangleMark(
                x: .value("Time", aggregate.timestamp),
                yStart: .value("Open", bodyBottom),
                yEnd: .value("Close", bodyTop),
                width: .ratio(0.7)
            )
            .foregroundStyle(isUp ? Color.green : Color.red)
            .opacity(1.0)
        }
        .chartXAxis {
            chartAxisConfiguration
        }
        .chartYAxis {
            chartYAxisConfiguration
        }
        .chartXScale(domain: visibleDateRange)
        .chartYScale(domain: visiblePriceRange)
        .frame(height: 200)
        .padding()
        .gesture(chartGestures)
    }
    
    private var lineChart: some View {
        Chart(filteredAggregates, id: \.id) { aggregate in
            LineMark(
                x: .value("Time", aggregate.timestamp),
                y: .value("Close", aggregate.close)
            )
            .foregroundStyle(.blue)
            .lineStyle(StrokeStyle(lineWidth: 1.5))
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis {
            chartAxisConfiguration
        }
        .chartYAxis {
            chartYAxisConfiguration
        }
        .chartXScale(domain: visibleDateRange)
        .chartYScale(domain: visiblePriceRange)
        .frame(height: 200)
        .padding()
        .gesture(chartGestures)
    }
    
    private var dotChart: some View {
        Chart(filteredAggregates, id: \.id) { aggregate in
            PointMark(
                x: .value("Time", aggregate.timestamp),
                y: .value("Close", aggregate.close)
            )
            .foregroundStyle(.blue)
            .symbolSize(30)
        }
        .chartXAxis {
            chartAxisConfiguration
        }
        .chartYAxis {
            chartYAxisConfiguration
        }
        .chartXScale(domain: visibleDateRange)
        .chartYScale(domain: visiblePriceRange)
        .frame(height: 200)
        .padding()
        .gesture(chartGestures)
    }
    
    private var histogramChart: some View {
        Chart(filteredAggregates, id: \.id) { aggregate in
            BarMark(
                x: .value("Time", aggregate.timestamp),
                yStart: .value("Low", aggregate.low),
                yEnd: .value("High", aggregate.high),
                width: .ratio(0.6)
            )
            .foregroundStyle(aggregate.close >= aggregate.open ? Color.green.opacity(0.6) : Color.red.opacity(0.6))
        }
        .chartXAxis {
            chartAxisConfiguration
        }
        .chartYAxis {
            chartYAxisConfiguration
        }
        .chartXScale(domain: visibleDateRange)
        .chartYScale(domain: visiblePriceRange)
        .frame(height: 200)
        .padding()
        .gesture(chartGestures)
    }
    
    // MARK: - Chart Configuration
    
    private var chartAxisConfiguration: some AxisContent {
        AxisMarks(values: .automatic(desiredCount: min(filteredAggregates.count, 8))) { value in
            AxisGridLine()
            if let date = value.as(Date.self) {
                AxisValueLabel {
                    Text(formatTime(date))
                        .font(.caption2)
                }
            }
        }
    }
    
    private var chartYAxisConfiguration: some AxisContent {
        AxisMarks(position: .leading) { value in
            AxisGridLine()
            if let price = value.as(Double.self) {
                AxisValueLabel {
                    Text(formatPrice(price))
                        .font(.caption2)
                }
            }
        }
    }
    
    private var chartGestures: some Gesture {
        SimultaneousGesture(
            // Two-finger pinch for zoom (MagnificationGesture only fires with 2+ fingers)
            MagnificationGesture()
                .onChanged { value in
                    // This only fires with two-finger pinch
                    if !isPinching {
                        isPinching = true
                    }
                    handleZoom(magnification: value)
                }
                .onEnded { _ in
                    lastMagnificationValue = 1.0
                    pinchStartLocation = .zero
                    pinchCurrentLocation = .zero
                    isPinching = false
                }
                .simultaneously(with:
                    // Track finger positions during pinch to determine direction
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // Only track if we're pinching (two fingers)
                            if isPinching {
                                if pinchStartLocation == .zero {
                                    pinchStartLocation = value.startLocation
                                }
                                pinchCurrentLocation = value.location
                            }
                        }
                        .onEnded { _ in
                            if isPinching {
                                pinchStartLocation = .zero
                                pinchCurrentLocation = .zero
                            }
                        }
                ),
            // Single finger drag for panning
            // This will only fire when MagnificationGesture is not active
            DragGesture(minimumDistance: 5)
                .onChanged { value in
                    // Only pan if we're not currently pinching
                    // MagnificationGesture takes priority, so if it's active, this won't fire
                    if !isPinching {
                        handlePan(translation: value.translation)
                    }
                }
                .onEnded { _ in
                    if !isPinching {
                        lastDragValue = .zero
                    }
                }
        )
    }
    
    // MARK: - Computed Properties
    
    private var filteredAggregates: [StockAggregate] {
        guard let visibleXRange = visibleXRange else {
            return aggregates
        }
        return aggregates.filter { visibleXRange.contains($0.timestamp) }
    }
    
    private var isZoomed: Bool {
        visibleXRange != nil || visibleYRange != nil
    }
    
    // MARK: - Zoom & Pan Functions
    
    private func resetZoom() {
        visibleXRange = nil
        visibleYRange = nil
        lastMagnificationValue = 1.0
        lastDragValue = .zero
    }
    
    private func handleZoom(magnification: CGFloat) {
        let delta = magnification / lastMagnificationValue
        lastMagnificationValue = magnification
        
        // Determine pinch direction (horizontal vs vertical)
        let pinchDirection = determinePinchDirection()
        
        let currentXRange = visibleXRange ?? fullDateRange
        let currentYRange = visibleYRange ?? fullPriceRange
        
        let xRangeSize = currentXRange.upperBound.timeIntervalSince(currentXRange.lowerBound)
        let yRangeSize = currentYRange.upperBound - currentYRange.lowerBound
        
        let xCenter = currentXRange.lowerBound.addingTimeInterval(xRangeSize / 2)
        let yCenter = (currentYRange.lowerBound + currentYRange.upperBound) / 2
        
        // Only zoom the axis that matches the pinch direction
        switch pinchDirection {
        case .horizontal:
            // Horizontal pinch - zoom X-axis (time)
            let newXRangeSize = xRangeSize / Double(delta)
            let newXLower = xCenter.addingTimeInterval(-newXRangeSize / 2)
            let newXUpper = xCenter.addingTimeInterval(newXRangeSize / 2)
            
            let clampedXLower = max(newXLower, fullDateRange.lowerBound)
            let clampedXUpper = min(newXUpper, fullDateRange.upperBound)
            visibleXRange = clampedXLower...clampedXUpper
            
            // Don't change Y-axis
            if visibleYRange == nil {
                visibleYRange = nil
            }
            
        case .vertical:
            // Vertical pinch - zoom Y-axis (price)
            let newYRangeSize = yRangeSize / Double(delta)
            let newYLower = yCenter - newYRangeSize / 2
            let newYUpper = yCenter + newYRangeSize / 2
            
            let clampedYLower = max(newYLower, fullPriceRange.lowerBound)
            let clampedYUpper = min(newYUpper, fullPriceRange.upperBound)
            visibleYRange = clampedYLower...clampedYUpper
            
            // Don't change X-axis
            if visibleXRange == nil {
                visibleXRange = nil
            }
            
        case .diagonal:
            // Diagonal pinch - ignore (don't zoom)
            return
        }
    }
    
    private func determinePinchDirection() -> PinchDirection {
        guard pinchStartLocation != .zero && pinchCurrentLocation != .zero else {
            return .diagonal // Default to diagonal if we don't have enough info
        }
        
        let deltaX = abs(pinchCurrentLocation.x - pinchStartLocation.x)
        let deltaY = abs(pinchCurrentLocation.y - pinchStartLocation.y)
        
        // If movement is too small, can't determine direction
        let minMovement: CGFloat = 5.0
        if deltaX < minMovement && deltaY < minMovement {
            return .diagonal
        }
        
        // Calculate the ratio to determine direction
        // For horizontal: deltaX >> deltaY
        // For vertical: deltaY >> deltaX
        let totalMovement = deltaX + deltaY
        let xRatio = deltaX / totalMovement
        let yRatio = deltaY / totalMovement
        
        // 5% variation tolerance: if one axis is 95%+ of movement, it's that direction
        let threshold: CGFloat = 0.95
        
        if xRatio >= threshold {
            return .horizontal
        } else if yRatio >= threshold {
            return .vertical
        } else {
            return .diagonal
        }
    }
    
    enum PinchDirection {
        case horizontal
        case vertical
        case diagonal
    }
    
    private func handlePan(translation: CGSize) {
        guard !aggregates.isEmpty else { return }
        
        let currentXRange = visibleXRange ?? fullDateRange
        let currentYRange = visibleYRange ?? fullPriceRange
        
        let xRangeSize = currentXRange.upperBound.timeIntervalSince(currentXRange.lowerBound)
        let yRangeSize = currentYRange.upperBound - currentYRange.lowerBound
        
        // Calculate pan distance as percentage of range
        // Assuming chart width ~400pt, height ~200pt
        let xPanRatio = Double(translation.width - lastDragValue.width) / 400.0
        let yPanRatio = Double(translation.height - lastDragValue.height) / 200.0
        
        let xPanDistance = xPanRatio * xRangeSize
        let yPanDistance = yPanRatio * yRangeSize
        
        let newXLower = currentXRange.lowerBound.addingTimeInterval(-xPanDistance)
        let newXUpper = currentXRange.upperBound.addingTimeInterval(-xPanDistance)
        let newYLower = currentYRange.lowerBound + yPanDistance
        let newYUpper = currentYRange.upperBound + yPanDistance
        
        // Clamp to full range
        let clampedXLower = max(newXLower, fullDateRange.lowerBound)
        let clampedXUpper = min(newXUpper, fullDateRange.upperBound)
        let clampedYLower = max(newYLower, fullPriceRange.lowerBound)
        let clampedYUpper = min(newYUpper, fullPriceRange.upperBound)
        
        // Only update if we're not at the boundaries
        if clampedXLower == fullDateRange.lowerBound && clampedXUpper == fullDateRange.upperBound {
            visibleXRange = nil
        } else {
            visibleXRange = clampedXLower...clampedXUpper
        }
        
        if clampedYLower == fullPriceRange.lowerBound && clampedYUpper == fullPriceRange.upperBound {
            visibleYRange = nil
        } else {
            visibleYRange = clampedYLower...clampedYUpper
        }
        
        lastDragValue = translation
    }
}

#Preview {
    StockChartView(
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
            ),
            StockAggregate(
                ticker: "AAPL",
                timestamp: Date().addingTimeInterval(300),
                open: 150.5,
                high: 151.0,
                low: 150.0,
                close: 150.8,
                volume: 1200000,
                granularityMinutes: 5
            )
        ],
        ticker: "AAPL"
    )
    .frame(width: 600, height: 250)
}
