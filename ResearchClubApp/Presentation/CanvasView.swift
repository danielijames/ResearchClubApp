//
//  CanvasView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI

struct CanvasView: View {
    @Binding var items: [CanvasItem]
    @State private var canvasOffset: CGSize = .zero
    @State private var canvasScale: CGFloat = 1.0
    @State private var lastMagnification: CGFloat = 1.0
    @State private var isDraggingCanvas: Bool = false
    @State private var dragStartLocation: CGPoint = .zero
    @State private var isDraggingItem: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Canvas background with grid
                CanvasBackgroundView()
                    .frame(width: geometry.size.width * 10, height: geometry.size.height * 10)
                    .offset(canvasOffset)
                    .scaleEffect(canvasScale)
                
                // Canvas items (sorted by zIndex, rendered with canvas transform)
                if items.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "square.on.square")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Canvas Ready")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Fetch stock data to create draggable windows")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ForEach(items.sorted(by: { $0.zIndex < $1.zIndex })) { item in
                        CanvasItemView(
                            item: item,
                            items: $items,
                            isDraggingItem: $isDraggingItem
                        )
                        .offset(canvasOffset)
                        .scaleEffect(canvasScale)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
            .gesture(
                SimultaneousGesture(
                    // Two-finger pinch for zoom
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastMagnification
                            canvasScale = max(0.1, min(3.0, canvasScale * delta))
                            lastMagnification = value
                        }
                        .onEnded { _ in
                            lastMagnification = 1.0
                        },
                    // Pan canvas (only if not dragging an item)
                    DragGesture(minimumDistance: 5)
                        .onChanged { value in
                            // Only pan canvas if we're not dragging an item
                            guard !isDraggingItem else { return }
                            
                            if !isDraggingCanvas {
                                isDraggingCanvas = true
                                dragStartLocation = value.startLocation
                            }
                            let delta = CGSize(
                                width: value.translation.width,
                                height: value.translation.height
                            )
                            canvasOffset = CGSize(
                                width: canvasOffset.width + delta.width / canvasScale,
                                height: canvasOffset.height + delta.height / canvasScale
                            )
                        }
                        .onEnded { _ in
                            isDraggingCanvas = false
                        }
                )
            )
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button(action: resetCanvas) {
                        Label("Reset View", systemImage: "arrow.counterclockwise")
                    }
                    Text("Zoom: \(Int(canvasScale * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func resetCanvas() {
        withAnimation(.easeOut(duration: 0.3)) {
            canvasOffset = .zero
            canvasScale = 1.0
        }
    }
}

struct CanvasBackgroundView: View {
    var body: some View {
        Canvas { context, size in
            // Draw grid
            let gridSize: CGFloat = 50
            let gridColor = Color(NSColor.separatorColor).opacity(0.3)
            
            // Vertical lines
            var x: CGFloat = 0
            while x < size.width {
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    },
                    with: .color(gridColor),
                    lineWidth: 0.5
                )
                x += gridSize
            }
            
            // Horizontal lines
            var y: CGFloat = 0
            while y < size.height {
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    },
                    with: .color(gridColor),
                    lineWidth: 0.5
                )
                y += gridSize
            }
        }
    }
}
