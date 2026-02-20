//
//  Cohort.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation
import SwiftUI

/// Represents a cohort - a collection of spreadsheets organized for research
struct Cohort: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var color: CohortColor
    var spreadsheetIds: Set<UUID>
    var createdAt: Date
    var description: String?
    
    init(
        id: UUID = UUID(),
        name: String,
        color: CohortColor = .blue,
        spreadsheetIds: Set<UUID> = [],
        createdAt: Date = Date(),
        description: String? = nil
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.spreadsheetIds = spreadsheetIds
        self.createdAt = createdAt
        self.description = description
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, name, color, spreadsheetIds, createdAt, description
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        color = try container.decode(CohortColor.self, forKey: .color)
        let idsArray = try container.decode([UUID].self, forKey: .spreadsheetIds)
        spreadsheetIds = Set(idsArray)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        description = try container.decodeIfPresent(String.self, forKey: .description)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(color, forKey: .color)
        try container.encode(Array(spreadsheetIds), forKey: .spreadsheetIds)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(description, forKey: .description)
    }
}

/// Available colors for cohorts
enum CohortColor: String, Codable, CaseIterable, Identifiable {
    case blue
    case purple
    case green
    case orange
    case red
    case pink
    case teal
    case indigo
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .pink: return .pink
        case .teal: return .teal
        case .indigo: return .indigo
        }
    }
}
