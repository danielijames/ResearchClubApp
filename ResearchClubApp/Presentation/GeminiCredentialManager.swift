//
//  GeminiCredentialManager.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation
import SwiftUI

/// Manages Gemini API key input, storage, and retrieval for the presentation layer.
/// Uses UseCase to interact with credential storage following Clean Architecture.
@MainActor
class GeminiCredentialManager: ObservableObject {
    @Published var apiKey: String = ""
    @Published var saveCredentials: Bool = false
    
    private let manageCredentialsUseCase: ManageCredentialsUseCase
    
    init(manageCredentialsUseCase: ManageCredentialsUseCase = ManageCredentialsUseCase()) {
        self.manageCredentialsUseCase = manageCredentialsUseCase
        loadSavedCredentials()
    }
    
    /// Loads saved Gemini API key from storage if it exists
    func loadSavedCredentials() {
        if let savedAPIKey = manageCredentialsUseCase.loadGeminiCredentials() {
            apiKey = savedAPIKey
            saveCredentials = true
        }
    }
    
    /// Saves Gemini API key to storage if saveCredentials is true
    /// - Throws: CredentialManagementError if save fails or API key is invalid
    func saveCredentialsIfNeeded() throws {
        if saveCredentials {
            if apiKey.isEmpty {
                // If checkbox is checked but field is empty, delete saved credentials
                manageCredentialsUseCase.deleteGeminiCredentials()
            } else {
                // Use case handles validation and saving
                try manageCredentialsUseCase.saveGeminiCredentials(apiKey)
            }
        } else {
            // If checkbox is unchecked, delete any saved credentials
            manageCredentialsUseCase.deleteGeminiCredentials()
        }
    }
    
    /// Deletes saved Gemini API key from storage
    func deleteSavedCredentials() {
        manageCredentialsUseCase.deleteGeminiCredentials()
    }
    
    /// Checks if Gemini API key is valid using business rules
    var hasValidCredentials: Bool {
        manageCredentialsUseCase.validateGeminiAPIKey(apiKey)
    }
    
    /// Checks if Gemini API key is currently saved
    var hasSavedCredentials: Bool {
        manageCredentialsUseCase.hasSavedGeminiCredentials()
    }
}
