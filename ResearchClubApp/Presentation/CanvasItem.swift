//
//  CanvasItem.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI

struct CanvasItem: Identifiable, Equatable {
    let id: UUID
    var position: CGPoint
    var size: CGSize
    var title: String
    var content: CanvasItemContent
    var zIndex: Int
    
    static func == (lhs: CanvasItem, rhs: CanvasItem) -> Bool {
        lhs.id == rhs.id
    }
    
    init(
        id: UUID = UUID(),
        position: CGPoint = CGPoint(x: 100, y: 100),
        size: CGSize = CGSize(width: 600, height: 500),
        title: String,
        content: CanvasItemContent,
        zIndex: Int = 0
    ) {
        self.id = id
        self.position = position
        self.size = size
        self.title = title
        self.content = content
        self.zIndex = zIndex
    }
}

enum CanvasItemContent: Equatable {
    case stockData(aggregates: [StockAggregate], ticker: String, granularity: AggregateGranularity, tickerDetails: TickerDetails?)
    case chart(aggregates: [StockAggregate], ticker: String, chartType: ChartType)
}

struct CanvasItemView: View {
    let item: CanvasItem
    @Binding var items: [CanvasItem]
    @Binding var isDraggingItem: Bool
    
    @State private var isDragging: Bool = false
    @State private var isResizing: Bool = false
    @State private var isSelected: Bool = false
    @State private var currentItem: CanvasItem
    @State private var resizeStartSize: CGSize = .zero
    @State private var resizeStartLocation: CGPoint = .zero
    @State private var dragStartPosition: CGPoint = .zero
    
    init(item: CanvasItem, items: Binding<[CanvasItem]>, isDraggingItem: Binding<Bool>) {
        self.item = item
        self._items = items
        self._isDraggingItem = isDraggingItem
        _currentItem = State(initialValue: item)
    }
    
    private let minSize: CGSize = CGSize(width: 300, height: 200)
    private let resizeHandleSize: CGFloat = 20
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            itemContentView
            resizeHandleView
        }
        .frame(width: currentItem.size.width, height: currentItem.size.height)
        .position(
            CGPoint(
                x: currentItem.position.x,
                y: currentItem.position.y
            )
        )
        .onTapGesture {
            selectItem()
        }
        .onChange(of: items) { _, newItems in
            updateCurrentItem(from: newItems)
        }
    }
    
    private var itemContentView: some View {
        VStack(spacing: 0) {
            titleBarView
            contentView
                .frame(width: currentItem.size.width, height: currentItem.size.height - 40)
        }
        .frame(width: currentItem.size.width, height: currentItem.size.height)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
    
    private var titleBarView: some View {
        HStack {
            Text(currentItem.title)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            Button(action: closeItem) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .highPriorityGesture(dragGesture)
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                handleDragChanged(value)
            }
            .onEnded { _ in
                handleDragEnded()
            }
    }
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        if !isDragging {
            isDragging = true
            isDraggingItem = true
            dragStartPosition = currentItem.position
        }
        
        // Calculate new position based on drag start position + translation
        let newPosition = CGPoint(
            x: dragStartPosition.x + value.translation.width,
            y: dragStartPosition.y + value.translation.height
        )
        currentItem.position = newPosition
        updateItemInArray()
    }
    
    private func handleDragEnded() {
        isDragging = false
        isDraggingItem = false
        updateItemInArray()
    }
    
    @ViewBuilder
    private var resizeHandleView: some View {
        if isSelected {
            Circle()
                .fill(Color.blue)
                .frame(width: resizeHandleSize, height: resizeHandleSize)
                .offset(
                    x: currentItem.size.width - resizeHandleSize / 2,
                    y: currentItem.size.height - resizeHandleSize / 2
                )
                .gesture(resizeGesture)
        }
    }
    
    private var resizeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                handleResizeChanged(value)
            }
            .onEnded { _ in
                handleResizeEnded()
            }
    }
    
    private func handleResizeChanged(_ value: DragGesture.Value) {
        if !isResizing {
            isResizing = true
            resizeStartSize = currentItem.size
            resizeStartLocation = value.startLocation
        }
        
        let delta = CGSize(
            width: value.translation.width,
            height: value.translation.height
        )
        
        let newSize = CGSize(
            width: max(minSize.width, resizeStartSize.width + delta.width),
            height: max(minSize.height, resizeStartSize.height + delta.height)
        )
        
        currentItem.size = newSize
        updateItemInArray()
    }
    
    private func handleResizeEnded() {
        isResizing = false
        updateItemInArray()
    }
    
    private func closeItem() {
        withAnimation {
            items.removeAll { $0.id == currentItem.id }
        }
    }
    
    private func selectItem() {
        isSelected = true
        guard let index = items.firstIndex(where: { $0.id == currentItem.id }) else { return }
        let maxZ = items.map { $0.zIndex }.max() ?? 0
        items[index].zIndex = maxZ + 1
        currentItem.zIndex = maxZ + 1
        // Deselect others
        for i in items.indices where i != index {
            items[i].zIndex = max(0, items[i].zIndex - 1)
        }
    }
    
    private func updateItemInArray() {
        guard let index = items.firstIndex(where: { $0.id == currentItem.id }) else { return }
        items[index] = currentItem
    }
    
    private func updateCurrentItem(from newItems: [CanvasItem]) {
        if let updatedItem = newItems.first(where: { $0.id == currentItem.id }) {
            currentItem = updatedItem
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch currentItem.content {
        case .stockData(let aggregates, let ticker, _, let tickerDetails):
            StockDataResultsView(aggregates: aggregates, ticker: ticker, tickerDetails: tickerDetails)
        case .chart(let aggregates, let ticker, let chartType):
            StockChartView(aggregates: aggregates, ticker: ticker, initialChartType: chartType)
        }
    }
}

// Environment key for chart type (if needed)
private struct ChartTypeKey: EnvironmentKey {
    static let defaultValue: ChartType = .candlestick
}

extension EnvironmentValues {
    var chartType: ChartType {
        get { self[ChartTypeKey.self] }
        set { self[ChartTypeKey.self] = newValue }
    }
}
