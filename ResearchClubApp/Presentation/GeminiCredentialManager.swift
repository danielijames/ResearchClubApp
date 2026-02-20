//
//  GeminiCredentialManager.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation
import SwiftUI

/// Manages Gemini API key input, storage, and retrieval for the presentation layer.
@MainActor
class GeminiCredentialManager: ObservableObject {
    @Published var apiKey: String = ""
    @Published var saveCredentials: Bool = false
    
    private let credentialStorage = CredentialStorage()
    
    init() {
        loadSavedCredentials()
    }
    
    /// Loads saved Gemini API key from secure storage if it exists
    func loadSavedCredentials() {
        if let savedAPIKey = try? credentialStorage.getGeminiAPIKey() {
            apiKey = savedAPIKey
            saveCredentials = true
        }
    }
    
    /// Saves Gemini API key to secure storage if saveCredentials is true
    func saveCredentialsIfNeeded() throws {
        if saveCredentials {
            if apiKey.isEmpty {
                // If checkbox is checked but field is empty, delete saved credentials
                credentialStorage.deleteGeminiAPIKey()
            } else {
                // Save the API key
                try credentialStorage.saveGeminiAPIKey(apiKey.trimmingCharacters(in: .whitespaces))
            }
        } else {
            // If checkbox is unchecked, delete any saved credentials
            credentialStorage.deleteGeminiAPIKey()
        }
    }
    
    /// Deletes saved Gemini API key from secure storage
    func deleteSavedCredentials() {
        credentialStorage.deleteGeminiAPIKey()
    }
    
    /// Checks if Gemini API key is currently saved
    var hasSavedCredentials: Bool {
        credentialStorage.hasSavedGeminiCredentials()
    }
}
