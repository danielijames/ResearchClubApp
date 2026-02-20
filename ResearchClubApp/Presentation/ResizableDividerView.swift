//
//  ResizableDividerView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI
import AppKit

struct ResizableDividerView: View {
    @Binding var isDragging: Bool
    @Binding var dragStartWidth: CGFloat
    let currentWidth: CGFloat
    let geometryWidth: CGFloat
    let minWidth: CGFloat
    let maxWidth: CGFloat
    let onWidthChanged: (CGFloat) -> Void
    let onDragEnded: () -> Void
    
    var body: some View {
        ZStack {
            // Visible divider line
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(width: 1)
            
            // Wider invisible hit area for easier dragging
            Rectangle()
                .fill(Color.clear)
                .frame(width: 12)
        }
        .frame(width: 12)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Capture starting width only once at the beginning of the drag
                    if !isDragging {
                        isDragging = true
                        // Use current width, or initialize to 40% if not set
                        let startWidth = currentWidth > 0 ? currentWidth : (geometryWidth * 0.4)
                        dragStartWidth = startWidth
                    }
                    
                    // Calculate new width based on drag translation
                    // Dragging left (negative translation) increases width
                    // Dragging right (positive translation) decreases width
                    let delta = -value.translation.width
                    let newWidth = dragStartWidth + delta
                    let clampedWidth = max(minWidth, min(maxWidth, newWidth))
                    
                    // Direct update without any animation or transaction overhead
                    onWidthChanged(clampedWidth)
                }
                .onEnded { _ in
                    // Reset drag state when drag ends
                    isDragging = false
                    dragStartWidth = 0
                    onDragEnded()
                }
        )
        .onHover { isHovering in
            if isHovering {
                NSCursor.resizeLeftRight.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
