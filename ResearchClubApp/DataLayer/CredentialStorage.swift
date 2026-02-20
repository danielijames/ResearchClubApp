//
//  CredentialStorage.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation

/// Storage for API credentials using UserDefaults
class CredentialStorage {
    private let userDefaults = UserDefaults.standard
    private let apiKeyKey = "massive_api_key"
    private let geminiApiKeyKey = "gemini_api_key"
    
    /// Saves the API key to UserDefaults
    /// - Parameter apiKey: The API key to save
    func saveAPIKey(_ apiKey: String) {
        userDefaults.set(apiKey, forKey: apiKeyKey)
    }
    
    /// Retrieves the saved API key from UserDefaults
    /// - Returns: The saved API key, or nil if not found
    func getAPIKey() -> String? {
        return userDefaults.string(forKey: apiKeyKey)
    }
    
    /// Deletes the saved API key from UserDefaults
    func deleteAPIKey() {
        userDefaults.removeObject(forKey: apiKeyKey)
    }
    
    /// Checks if credentials are saved
    /// - Returns: True if credentials exist
    func hasSavedCredentials() -> Bool {
        return getAPIKey() != nil
    }
    
    // MARK: - Gemini API Key Storage
    
    func saveGeminiAPIKey(_ apiKey: String) {
        userDefaults.set(apiKey, forKey: geminiApiKeyKey)
    }
    
    func getGeminiAPIKey() -> String? {
        return userDefaults.string(forKey: geminiApiKeyKey)
    }
    
    func deleteGeminiAPIKey() {
        userDefaults.removeObject(forKey: geminiApiKeyKey)
    }
    
    func hasSavedGeminiCredentials() -> Bool {
        return getGeminiAPIKey() != nil
    }
}

// MARK: - Errors

enum CredentialStorageError: LocalizedError {
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid credential data"
        }
    }
}
