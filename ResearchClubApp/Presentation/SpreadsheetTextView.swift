//
//  SpreadsheetTextView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI
import AppKit

struct SpreadsheetTextView: View {
    let spreadsheet: SavedSpreadsheet
    let onBack: () -> Void
    let onCopy: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
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
                Button(action: onCopy) {
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
                Text(loadSpreadsheetText())
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadSpreadsheetText() -> String {
        do {
            let content = try String(contentsOf: spreadsheet.fileURL, encoding: .utf8)
            return content
        } catch {
            return "Error loading file: \(error.localizedDescription)"
        }
    }
}
