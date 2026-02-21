//
//  CredentialManager.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation
import SwiftUI

/// Manages credential input, storage, and retrieval for the presentation layer.
/// Uses UseCase to interact with credential storage following Clean Architecture.
@MainActor
class CredentialManager: ObservableObject {
    @Published var apiKey: String = ""
    @Published var saveCredentials: Bool = false
    
    private let manageCredentialsUseCase: ManageCredentialsUseCase
    
    init(manageCredentialsUseCase: ManageCredentialsUseCase = ManageCredentialsUseCase()) {
        self.manageCredentialsUseCase = manageCredentialsUseCase
        loadSavedCredentials()
    }
    
    /// Loads saved credentials from storage if they exist
    func loadSavedCredentials() {
        print("🔑 CredentialManager.loadSavedCredentials() called")
        if let savedAPIKey = manageCredentialsUseCase.loadSavedCredentials() {
            print("✅ Found saved API key, length: \(savedAPIKey.count)")
            apiKey = savedAPIKey
            saveCredentials = manageCredentialsUseCase.getSaveCredentialsState()
            print("   Save credentials checkbox state: \(saveCredentials)")
        } else {
            print("ℹ️ No saved API key found")
            saveCredentials = manageCredentialsUseCase.getSaveCredentialsState()
            print("   Save credentials checkbox state: \(saveCredentials)")
        }
        print("   Current API key length: \(apiKey.count)")
    }
    
    /// Saves credentials to secure storage if saveCredentials is true
    /// - Throws: CredentialManagementError or CredentialStorageError if save fails
    func saveCredentialsIfNeeded() throws {
        // Always save the checkbox state
        manageCredentialsUseCase.setSaveCredentialsState(saveCredentials)
        
        if saveCredentials {
            if apiKey.isEmpty {
                // If checkbox is checked but field is empty, delete saved credentials
                manageCredentialsUseCase.deleteCredentials()
            } else {
                // Use case handles validation and saving
                try manageCredentialsUseCase.saveCredentials(apiKey)
            }
        } else {
            // If checkbox is unchecked, delete any saved credentials
            manageCredentialsUseCase.deleteCredentials()
        }
    }
    
    /// Deletes saved credentials from secure storage
    func deleteSavedCredentials() {
        manageCredentialsUseCase.deleteCredentials()
    }
    
    /// Checks if credentials are valid using business rules
    var hasValidCredentials: Bool {
        manageCredentialsUseCase.validateAPIKey(apiKey)
    }
    
    /// Checks if credentials are currently saved
    var hasSavedCredentials: Bool {
        manageCredentialsUseCase.hasSavedCredentials()
    }
    
    /// Creates a repository instance with the current API key
    /// - Returns: Repository instance if credentials are valid, nil otherwise
    func createRepository() -> MassiveRepositoryImpl? {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespaces)
        print("🔑 CredentialManager.createRepository() called")
        print("   API key length: \(apiKey.count)")
        print("   Trimmed key length: \(trimmedKey.count)")
        print("   Has valid credentials: \(hasValidCredentials)")
        
        guard hasValidCredentials else {
            print("❌ Credentials are not valid, returning nil")
            return nil
        }
        
        let repo = MassiveRepositoryImpl(apiKey: trimmedKey)
        print("✅ Created repository with key length: \(trimmedKey.count)")
        return repo
    }
}
