//
//  AppStateManager.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation

class AppStateManager {
    static let shared = AppStateManager()
    
    private let storageKey = "app_state"
    
    private init() {}
    
    /// Save application state to UserDefaults
    func saveState(_ state: AppState) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(state)
            UserDefaults.standard.set(data, forKey: storageKey)
            print("✅ Saved application state")
        } catch {
            print("❌ Failed to save application state: \(error.localizedDescription)")
        }
    }
    
    /// Load application state from UserDefaults
    func loadState() -> AppState? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            print("ℹ️ No saved application state found")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let state = try decoder.decode(AppState.self, from: data)
            print("✅ Loaded application state")
            return state
        } catch {
            print("❌ Failed to load application state: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Clear saved application state
    func clearState() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        print("🗑️ Cleared application state")
    }
}
