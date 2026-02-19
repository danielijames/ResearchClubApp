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
    
    /// Loads saved credentials from secure storage
    /// - Returns: The saved API key if it exists, nil otherwise
    /// - Throws: CredentialStorageError if retrieval fails
    func loadSavedCredentials() throws -> String? {
        return try credentialStorage.getAPIKey()
    }
    
    /// Saves credentials to secure storage
    /// - Parameter apiKey: The API key to save
    /// - Throws: CredentialStorageError if save fails or API key is invalid
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
        
        try credentialStorage.saveAPIKey(trimmedKey)
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
