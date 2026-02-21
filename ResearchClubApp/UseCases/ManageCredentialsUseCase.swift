//
//  ManageCredentialsUseCase.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation

/// Use case for managing API credentials securely.
/// Encapsulates business logic for saving, retrieving, and validating credentials.
struct ManageCredentialsUseCase {
    private let credentialStorage: CredentialStorage
    
    init(credentialStorage: CredentialStorage = CredentialStorage()) {
        self.credentialStorage = credentialStorage
    }
    
    /// Loads saved credentials from storage
    /// - Returns: The saved API key if it exists, nil otherwise
    func loadSavedCredentials() -> String? {
        return credentialStorage.getAPIKey()
    }
    
    /// Saves credentials to storage
    /// - Parameter apiKey: The API key to save
    /// - Throws: CredentialManagementError if API key is invalid
    func saveCredentials(_ apiKey: String) throws {
        // Business logic: Validate API key before saving
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespaces)
        guard !trimmedKey.isEmpty else {
            throw CredentialManagementError.emptyAPIKey
        }
        
        // Business logic: Basic validation (could add more checks)
        guard trimmedKey.count >= 10 else {
            throw CredentialManagementError.invalidAPIKey("API key appears to be too short")
        }
        
        credentialStorage.saveAPIKey(trimmedKey)
    }
    
    /// Deletes saved credentials from secure storage
    func deleteCredentials() {
        credentialStorage.deleteAPIKey()
    }
    
    /// Checks if credentials are currently saved
    /// - Returns: True if credentials exist in storage
    func hasSavedCredentials() -> Bool {
        return credentialStorage.hasSavedCredentials()
    }
    
    /// Validates an API key format (business rule)
    /// - Parameter apiKey: The API key to validate
    /// - Returns: True if the API key appears valid
    func validateAPIKey(_ apiKey: String) -> Bool {
        let trimmed = apiKey.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && trimmed.count >= 10
    }
    
    /// Saves the "save credentials" checkbox state
    func setSaveCredentialsState(_ value: Bool) {
        credentialStorage.setSaveCredentials(value)
    }
    
    /// Gets the "save credentials" checkbox state
    func getSaveCredentialsState() -> Bool {
        return credentialStorage.getSaveCredentials()
    }
    
    // MARK: - Gemini API Key Management
    
    /// Loads saved Gemini API key from storage
    /// - Returns: The saved Gemini API key if it exists, nil otherwise
    func loadGeminiCredentials() -> String? {
        return credentialStorage.getGeminiAPIKey()
    }
    
    /// Saves Gemini API key to storage
    /// - Parameter apiKey: The Gemini API key to save
    /// - Throws: CredentialManagementError if API key is invalid
    func saveGeminiCredentials(_ apiKey: String) throws {
        // Business logic: Validate API key before saving
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespaces)
        guard !trimmedKey.isEmpty else {
            throw CredentialManagementError.emptyAPIKey
        }
        
        // Business logic: Basic validation (could add more checks)
        guard trimmedKey.count >= 10 else {
            throw CredentialManagementError.invalidAPIKey("API key appears to be too short")
        }
        
        credentialStorage.saveGeminiAPIKey(trimmedKey)
    }
    
    /// Deletes saved Gemini API key from storage
    func deleteGeminiCredentials() {
        credentialStorage.deleteGeminiAPIKey()
    }
    
    /// Checks if Gemini credentials are currently saved
    /// - Returns: True if Gemini credentials exist in storage
    func hasSavedGeminiCredentials() -> Bool {
        return credentialStorage.hasSavedGeminiCredentials()
    }
    
    /// Validates a Gemini API key format (business rule)
    /// - Parameter apiKey: The Gemini API key to validate
    /// - Returns: True if the API key appears valid
    func validateGeminiAPIKey(_ apiKey: String) -> Bool {
        let trimmed = apiKey.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && trimmed.count >= 10
    }
    
    /// Saves the "save Gemini credentials" checkbox state
    func setGeminiSaveCredentialsState(_ value: Bool) {
        credentialStorage.setGeminiSaveCredentials(value)
    }
    
    /// Gets the "save Gemini credentials" checkbox state
    func getGeminiSaveCredentialsState() -> Bool {
        return credentialStorage.getGeminiSaveCredentials()
    }
}

// MARK: - Errors

enum CredentialManagementError: LocalizedError {
    case emptyAPIKey
    case invalidAPIKey(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyAPIKey:
            return "API key cannot be empty"
        case .invalidAPIKey(let message):
            return "Invalid API key: \(message)"
        }
    }
}
