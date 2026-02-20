//
//  SettingsView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var credentialManager: CredentialManager
    @ObservedObject var geminiCredentialManager: GeminiCredentialManager
    @Binding var isPresented: Bool
    var onUpdate: (() -> Void)?
    
    @Binding var cohorts: [Cohort]
    @Binding var spreadsheets: [SavedSpreadsheet]
    let spreadsheetExporter: SpreadsheetExporter
    let onCohortDeleted: (UUID) -> Void
    let onSpreadsheetDeleted: () -> Void
    
    @State private var showDeletionManager = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // API Credentials Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("API Credentials")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        // Massive API Key
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Massive API Key")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            SecureField("Enter your API key", text: $credentialManager.apiKey)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: credentialManager.apiKey) { _, _ in
                                    if credentialManager.saveCredentials {
                                        saveCredentials()
                                    }
                                }
                            
                            Toggle("Save credentials securely", isOn: $credentialManager.saveCredentials)
                                .onChange(of: credentialManager.saveCredentials) { _, newValue in
                                    if newValue {
                                        saveCredentials()
                                    } else {
                                        credentialManager.deleteSavedCredentials()
                                    }
                                }
                        }
                        
                        Divider()
                        
                        // Gemini API Key
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gemini API Key")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            SecureField("Enter Gemini API key", text: $geminiCredentialManager.apiKey)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: geminiCredentialManager.apiKey) { _, _ in
                                    if geminiCredentialManager.saveCredentials {
                                        try? geminiCredentialManager.saveCredentialsIfNeeded()
                                    }
                                }
                            
                            Toggle("Save Gemini API key securely", isOn: $geminiCredentialManager.saveCredentials)
                                .onChange(of: geminiCredentialManager.saveCredentials) { _, newValue in
                                    if newValue {
                                        try? geminiCredentialManager.saveCredentialsIfNeeded()
                                    } else {
                                        geminiCredentialManager.deleteSavedCredentials()
                                    }
                                }
                            
                            Text("Get your free API key at https://aistudio.google.com/apikey")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    Divider()
                    
                    // Deletion Management Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Data Management")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Permanently delete cohorts and spreadsheets")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showDeletionManager = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "trash")
                                Text("Open Deletion Manager")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.red)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                .padding()
            }
        }
        .frame(width: 500, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showDeletionManager) {
            DeletionManagerView(
                cohorts: $cohorts,
                spreadsheets: $spreadsheets,
                spreadsheetExporter: spreadsheetExporter,
                onCohortDeleted: onCohortDeleted,
                onSpreadsheetDeleted: onSpreadsheetDeleted
            )
        }
    }
    
    private func saveCredentials() {
        onUpdate?()
    }
}
