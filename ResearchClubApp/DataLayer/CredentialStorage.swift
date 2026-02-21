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
    private let saveCredentialsKey = "massive_save_credentials"
    private let geminiSaveCredentialsKey = "gemini_save_credentials"
    
    /// Saves the API key to UserDefaults
    /// - Parameter apiKey: The API key to save
    func saveAPIKey(_ apiKey: String) {
        print("💾 CredentialStorage.saveAPIKey() called")
        print("   Key length: \(apiKey.count)")
        print("   Key prefix: \(apiKey.prefix(8))...")
        userDefaults.set(apiKey, forKey: apiKeyKey)
        userDefaults.synchronize() // Force immediate write
        print("✅ API Key saved to UserDefaults with key: \(apiKeyKey)")
        
        // Verify it was saved
        if let saved = userDefaults.string(forKey: apiKeyKey) {
            print("✅ Verified: API Key retrieved from UserDefaults, length: \(saved.count)")
        } else {
            print("❌ ERROR: API Key was NOT saved to UserDefaults!")
        }
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
    
    /// Saves the "save credentials" checkbox state
    func setSaveCredentials(_ value: Bool) {
        userDefaults.set(value, forKey: saveCredentialsKey)
    }
    
    /// Gets the "save credentials" checkbox state
    func getSaveCredentials() -> Bool {
        return userDefaults.bool(forKey: saveCredentialsKey)
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
    
    /// Saves the "save Gemini credentials" checkbox state
    func setGeminiSaveCredentials(_ value: Bool) {
        userDefaults.set(value, forKey: geminiSaveCredentialsKey)
    }
    
    /// Gets the "save Gemini credentials" checkbox state
    func getGeminiSaveCredentials() -> Bool {
        return userDefaults.bool(forKey: geminiSaveCredentialsKey)
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
