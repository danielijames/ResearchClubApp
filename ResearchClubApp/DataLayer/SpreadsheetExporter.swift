//
//  SpreadsheetExporter.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation

struct SavedSpreadsheet: Identifiable, Equatable {
    let id: UUID
    let fileURL: URL
    let ticker: String
    let date: Date
    let granularity: AggregateGranularity
    let dataPointCount: Int
    let createdAt: Date
    var isSelectedForLLM: Bool
    
    init(
        id: UUID = UUID(),
        fileURL: URL,
        ticker: String,
        date: Date,
        granularity: AggregateGranularity,
        dataPointCount: Int,
        createdAt: Date = Date(),
        isSelectedForLLM: Bool = false
    ) {
        self.id = id
        self.fileURL = fileURL
        self.ticker = ticker
        self.date = date
        self.granularity = granularity
        self.dataPointCount = dataPointCount
        self.createdAt = createdAt
        self.isSelectedForLLM = isSelectedForLLM
    }
    
    var displayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        return "\(ticker.uppercased())_\(dateStr)_\(granularity.displayName.replacingOccurrences(of: " ", with: ""))"
    }
    
    var fileName: String {
        fileURL.lastPathComponent
    }
}

class SpreadsheetExporter {
    private let documentsDirectory: URL
    private let metadataFileURL: URL
    private var llmSelectionMetadata: [UUID: Bool] = [:]
    
    init() {
        // Get the application's documents directory
        let fileManager = FileManager.default
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ResearchClubApp", isDirectory: true)
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
        
        // Metadata file for LLM selection state
        metadataFileURL = documentsDirectory.appendingPathComponent("llm_selections.json")
        loadLLMSelections()
    }
    
    func exportToXLSX(
        aggregates: [StockAggregate],
        ticker: String,
        date: Date,
        granularity: AggregateGranularity
    ) throws -> SavedSpreadsheet {
        // Create filename with timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let dateStr = formatter.string(from: date)
        let fileName = "\(ticker.uppercased())_\(dateStr)_\(granularity.displayName.replacingOccurrences(of: " ", with: "")).xlsx"
        
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        // Create CSV content (Excel can open CSV files)
        var csvContent = "Ticker,Timestamp,Open,High,Low,Close,Volume,Granularity (minutes)\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for aggregate in aggregates.sorted(by: { $0.timestamp < $1.timestamp }) {
            let timestampStr = dateFormatter.string(from: aggregate.timestamp)
            csvContent += "\(aggregate.ticker),\(timestampStr),\(aggregate.open),\(aggregate.high),\(aggregate.low),\(aggregate.close),\(aggregate.volume),\(aggregate.granularityMinutes)\n"
        }
        
        // Write to file
        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        // Create saved spreadsheet metadata
        let spreadsheetId = UUID()
        let savedSpreadsheet = SavedSpreadsheet(
            id: spreadsheetId,
            fileURL: fileURL,
            ticker: ticker,
            date: date,
            granularity: granularity,
            dataPointCount: aggregates.count,
            isSelectedForLLM: false
        )
        
        print("✅ Exported \(aggregates.count) data points to: \(fileURL.path)")
        
        return savedSpreadsheet
    }
    
    func getAllSavedSpreadsheets() -> [SavedSpreadsheet] {
        let fileManager = FileManager.default
        
        guard let files = try? fileManager.contentsOfDirectory(
            at: documentsDirectory,
            includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else {
            return []
        }
        
        var spreadsheets: [SavedSpreadsheet] = []
        
        for fileURL in files where fileURL.pathExtension == "xlsx" {
            // Parse filename to extract metadata
            let fileName = fileURL.deletingPathExtension().lastPathComponent
            let components = fileName.components(separatedBy: "_")
            
            if components.count >= 3 {
                let ticker = components[0]
                let dateStr = components[1]
                let granularityStr = components[2]
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                if let date = dateFormatter.date(from: dateStr) {
                    // Find matching granularity
                    let granularity = AggregateGranularity.allCases.first { granularity in
                        granularity.displayName.replacingOccurrences(of: " ", with: "").lowercased() == granularityStr.lowercased()
                    } ?? .fiveMinutes
                    
                    // Get file attributes
                    if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                       let creationDate = attributes[.creationDate] as? Date {
                        
                        // Count lines in file to get data point count
                        let dataPointCount = countDataPoints(in: fileURL)
                        
                        // Generate a stable ID based on file path for existing files
                        // This ensures we can track LLM selections even after app restarts
                        let stableId = generateStableID(from: fileURL.path)
                        
                        // Check if we have LLM selection metadata for this file
                        let isSelectedForLLM = llmSelectionMetadata[stableId] ?? false
                        
                        let spreadsheet = SavedSpreadsheet(
                            id: stableId,
                            fileURL: fileURL,
                            ticker: ticker,
                            date: date,
                            granularity: granularity,
                            dataPointCount: dataPointCount,
                            createdAt: creationDate,
                            isSelectedForLLM: isSelectedForLLM
                        )
                        spreadsheets.append(spreadsheet)
                    }
                }
            }
        }
        
        // Sort by creation date (newest first)
        return spreadsheets.sorted { $0.createdAt > $1.createdAt }
    }
    
    private func countDataPoints(in fileURL: URL) -> Int {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return 0
        }
        let lines = content.components(separatedBy: .newlines)
        // Subtract 1 for header line
        return max(0, lines.count - 1)
    }
    
    func deleteSpreadsheet(_ spreadsheet: SavedSpreadsheet) throws {
        let fileManager = FileManager.default
        try fileManager.removeItem(at: spreadsheet.fileURL)
        // Remove from metadata
        llmSelectionMetadata.removeValue(forKey: spreadsheet.id)
        saveLLMSelections()
    }
    
    func updateLLMSelection(for spreadsheet: SavedSpreadsheet, isSelected: Bool) {
        llmSelectionMetadata[spreadsheet.id] = isSelected
        saveLLMSelections()
    }
    
    func getSelectedSpreadsheetsForLLM(from spreadsheets: [SavedSpreadsheet]) -> [SavedSpreadsheet] {
        return spreadsheets.filter { $0.isSelectedForLLM }
    }
    
    // MARK: - Private Methods
    
    private func generateStableID(from filePath: String) -> UUID {
        // Create a UUID from the MD5 hash of the file path
        let hash = filePath.md5Hash
        // Take first 32 characters and format as UUID
        let uuidString = String(hash.prefix(32))
        
        let part1 = String(uuidString.prefix(8))
        let part2 = String(uuidString.dropFirst(8).prefix(4))
        let part3 = String(uuidString.dropFirst(12).prefix(4))
        let part4 = String(uuidString.dropFirst(16).prefix(4))
        let part5 = String(uuidString.dropFirst(20).prefix(12))
        
        let formattedUUID = "\(part1)-\(part2)-\(part3)-\(part4)-\(part5)"
        
        return UUID(uuidString: formattedUUID) ?? UUID()
    }
    
    private func loadLLMSelections() {
        guard let data = try? Data(contentsOf: metadataFileURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Bool] else {
            return
        }
        
        // Convert string keys to UUIDs
        for (key, value) in json {
            if let uuid = UUID(uuidString: key) {
                llmSelectionMetadata[uuid] = value
            }
        }
    }
    
    private func saveLLMSelections() {
        // Convert UUID keys to strings for JSON
        let json: [String: Bool] = Dictionary(uniqueKeysWithValues: llmSelectionMetadata.map { ($0.key.uuidString, $0.value) })
        
        if let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            try? data.write(to: metadataFileURL)
        }
    }
}
