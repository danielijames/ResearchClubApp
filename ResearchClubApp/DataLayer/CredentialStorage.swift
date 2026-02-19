//
//  CredentialStorage.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation
import Security

/// Secure storage for API credentials using Keychain Services
class CredentialStorage {
    private let serviceName = "com.researchclubapp.massiveapi"
    private let apiKeyKey = "massive_api_key"
    
    /// Saves the API key securely to Keychain
    /// - Parameter apiKey: The API key to save
    /// - Throws: Keychain error if save fails
    func saveAPIKey(_ apiKey: String) throws {
        guard let data = apiKey.data(using: .utf8) else {
            throw CredentialStorageError.invalidData
        }
        
        // Check if item already exists
        let searchQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: apiKeyKey
        ]
        
        var result: AnyObject?
        let searchStatus = SecItemCopyMatching(searchQuery as CFDictionary, &result)
        
        if searchStatus == errSecSuccess {
            // Item exists - update it instead of deleting and recreating
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: apiKeyKey
            ]
            
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]
            
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw CredentialStorageError.saveFailed(updateStatus)
            }
        } else {
            // Item doesn't exist - create it
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: apiKeyKey,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
            ]
            
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw CredentialStorageError.saveFailed(addStatus)
            }
        }
    }
    
    /// Retrieves the saved API key from Keychain
    /// - Returns: The saved API key, or nil if not found
    /// - Throws: Keychain error if retrieval fails
    func getAPIKey() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: apiKeyKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status != errSecItemNotFound else {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw CredentialStorageError.retrievalFailed(status)
        }
        
        guard let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            throw CredentialStorageError.invalidData
        }
        
        return apiKey
    }
    
    /// Deletes the saved API key from Keychain
    func deleteAPIKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: apiKeyKey
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    /// Checks if credentials are saved
    /// - Returns: True if credentials exist in Keychain
    func hasSavedCredentials() -> Bool {
        return (try? getAPIKey()) != nil
    }
}

// MARK: - Errors

enum CredentialStorageError: LocalizedError {
    case invalidData
    case saveFailed(OSStatus)
    case retrievalFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid credential data"
        case .saveFailed(let status):
            return "Failed to save credentials: \(status)"
        case .retrievalFailed(let status):
            return "Failed to retrieve credentials: \(status)"
        }
    }
}
