//
//  GeminiChatView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI

struct ChatMessage: Identifiable {
    let id: UUID
    let role: ChatRole
    let content: String
    let timestamp: Date
    
    init(id: UUID = UUID(), role: ChatRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

enum ChatRole {
    case user
    case assistant
    
    var displayName: String {
        switch self {
        case .user: return "You"
        case .assistant: return "Gemini"
        }
    }
}

struct GeminiChatView: View {
    let selectedSpreadsheets: [SavedSpreadsheet]
    @Binding var geminiAPIKey: String
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var errorMessage: String?
    
    private var geminiService: GeminiService? {
        guard !geminiAPIKey.isEmpty else { return nil }
        return GeminiService(apiKey: geminiAPIKey.trimmingCharacters(in: .whitespaces))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                Text("Gemini Analysis")
                    .font(.headline)
                Spacer()
                if selectedSpreadsheets.isEmpty {
                    Text("No spreadsheets selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(selectedSpreadsheets.count) spreadsheet\(selectedSpreadsheets.count == 1 ? "" : "s") selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Chat Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if messages.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue.opacity(0.6))
                                Text("Ask questions about your selected stock data")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if selectedSpreadsheets.isEmpty {
                                    Text("Select spreadsheets above to enable analysis")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        } else {
                            ForEach(messages) { message in
                                ChatBubbleView(message: message)
                                    .id(message.id)
                            }
                        }
                        
                        if isSending {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Analyzing...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Error Message
            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
            }
            
            Divider()
            
            // Input Area
            HStack(spacing: 12) {
                TextField("Ask about your stock data...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .disabled(isSending || geminiAPIKey.isEmpty || selectedSpreadsheets.isEmpty)
                
                Button(action: sendMessage) {
                    if isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending || geminiAPIKey.isEmpty || selectedSpreadsheets.isEmpty)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(height: 300)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            if messages.isEmpty && !selectedSpreadsheets.isEmpty {
                addWelcomeMessage()
            }
        }
        .onChange(of: selectedSpreadsheets.count) { _, _ in
            if messages.isEmpty && !selectedSpreadsheets.isEmpty {
                addWelcomeMessage()
            }
        }
    }
    
    private func addWelcomeMessage() {
        let welcomeText = """
        I have access to \(selectedSpreadsheets.count) spreadsheet\(selectedSpreadsheets.count == 1 ? "" : "s") of stock data. 
        You can ask me about:
        • Price trends and patterns
        • Volume analysis
        • Volatility indicators
        • Anomalies or unusual patterns
        • Correlations between metrics
        
        What would you like to know?
        """
        messages.append(ChatMessage(role: .assistant, content: welcomeText))
    }
    
    private func sendMessage() {
        let userMessage = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty,
              let service = geminiService,
              !selectedSpreadsheets.isEmpty else {
            return
        }
        
        // Add user message
        let userChatMessage = ChatMessage(role: .user, content: userMessage)
        messages.append(userChatMessage)
        inputText = ""
        errorMessage = nil
        isSending = true
        
        Task {
            do {
                // Load selected spreadsheets data
                let context = await loadSelectedSpreadsheetsData()
                
                // Send to Gemini
                let response = try await service.sendMessage(
                    userMessage: userMessage,
                    context: context
                )
                
                // Add assistant response
                await MainActor.run {
                    messages.append(ChatMessage(role: .assistant, content: response))
                    isSending = false
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func loadSelectedSpreadsheetsData() async -> String {
        var context = "Stock Market Data:\n\n"
        
        for spreadsheet in selectedSpreadsheets {
            do {
                let content = try String(contentsOf: spreadsheet.fileURL, encoding: .utf8)
                context += "=== \(spreadsheet.displayName) ===\n"
                context += "Ticker: \(spreadsheet.ticker)\n"
                context += "Date: \(formatDate(spreadsheet.date))\n"
                context += "Granularity: \(spreadsheet.granularity.displayName)\n"
                context += "Data Points: \(spreadsheet.dataPointCount)\n\n"
                context += "CSV Data:\n\(content)\n\n"
            } catch {
                context += "=== \(spreadsheet.displayName) ===\n"
                context += "Error loading data: \(error.localizedDescription)\n\n"
            }
        }
        
        return context
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.role.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(message.content)
                    .padding(12)
                    .background(
                        message.role == .user
                            ? Color.blue.opacity(0.2)
                            : Color(NSColor.controlBackgroundColor)
                    )
                    .cornerRadius(12)
                    .textSelection(.enabled)
            }
            
            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }
}
