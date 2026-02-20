//
//  GeminiChatView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI
import AppKit

struct ChatMessage: Identifiable, Codable {
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

enum ChatRole: String, Codable {
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
    @Binding var messages: [ChatMessage]
    let tabId: UUID
    
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var errorMessage: String?
    @FocusState private var isInputFocused: Bool
    
    private var conversationStorageKey: String {
        "gemini_conversation_\(tabId.uuidString)"
    }
    
    private var geminiService: GeminiService? {
        guard !geminiAPIKey.isEmpty else { return nil }
        return GeminiService(apiKey: geminiAPIKey.trimmingCharacters(in: .whitespaces))
    }
    
    // MARK: - Persistence
    
    private func loadConversation() {
        // Load from UserDefaults if messages binding is empty
        if messages.isEmpty {
            if let data = UserDefaults.standard.data(forKey: conversationStorageKey),
               let decoded = try? JSONDecoder().decode([ChatMessage].self, from: data) {
                messages = decoded
            }
        }
    }
    
    private func clearConversation() {
        messages = []
        UserDefaults.standard.removeObject(forKey: conversationStorageKey)
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
                
                // Erase conversation button
                if !messages.isEmpty {
                    Button(action: {
                        clearConversation()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("Erase")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    .help("Clear conversation history")
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
                .onChange(of: messages.count) { oldValue, newValue in
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
            HStack(alignment: .bottom, spacing: 12) {
                ZStack(alignment: .topLeading) {
                    // Multi-line text input
                    TextEditor(text: $inputText)
                        .font(.body)
                        .frame(minHeight: 44, maxHeight: 88) // Twice as large (was ~44, now 88 max)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isInputFocused ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: isInputFocused ? 2 : 1)
                        )
                        .focused($isInputFocused)
                        .onKeyPress(.return) {
                            // Check if Shift is pressed using NSEvent
                            if let currentEvent = NSApp.currentEvent, currentEvent.modifierFlags.contains(.shift) {
                                // Shift+Enter: Insert newline (default behavior)
                                return .ignored
                            } else {
                                // Enter: Send message
                                if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                                   !isSending,
                                   !geminiAPIKey.isEmpty,
                                   !selectedSpreadsheets.isEmpty {
                                    sendMessage()
                                }
                                return .handled
                            }
                        }
                    
                    // Placeholder text (only when empty and not focused)
                    if inputText.isEmpty && !isInputFocused {
                        Text("Ask about your stock data...")
                            .foregroundColor(Color(NSColor.placeholderTextColor))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false) // Don't block clicks to TextEditor
                    }
                }
                
                Button(action: sendMessage) {
                    if isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSending)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            // Load persisted conversation first if messages are empty
            if messages.isEmpty {
                loadConversation()
            }
            
            // Only add welcome message if conversation is empty and spreadsheets are selected
            if messages.isEmpty && !selectedSpreadsheets.isEmpty {
                addWelcomeMessage()
            }
        }
        .onChange(of: selectedSpreadsheets.count) { oldValue, newValue in
            // Don't reset conversation when spreadsheets change
            // Conversation persists regardless of selected spreadsheets
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
        var updatedMessages = messages
        updatedMessages.append(ChatMessage(role: .assistant, content: welcomeText))
        messages = updatedMessages
    }
    
    private func sendMessage() {
        let userMessage = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Don't send if already sending or message is empty
        guard !isSending, !userMessage.isEmpty else {
            return
        }
        
        // Check for API key and show error if missing
        guard let service = geminiService else {
            errorMessage = "Gemini API key is not configured. Please set it in settings."
            return
        }
        
        // Add user message
        let userChatMessage = ChatMessage(role: .user, content: userMessage)
        var updatedMessages = messages
        updatedMessages.append(userChatMessage)
        messages = updatedMessages
        inputText = ""
        errorMessage = nil
        isSending = true
        
        Task {
            do {
                // Load selected spreadsheets data (empty string if none selected)
                let context = selectedSpreadsheets.isEmpty ? "" : await loadSelectedSpreadsheetsData()
                
                // Build conversation history from previous messages (excluding welcome message)
                // Convert ChatMessage to GeminiMessage format for API
                let conversationHistory = buildConversationHistory()
                
                // Send to Gemini - only the user's message, with conversation history for context
                let response = try await service.sendMessage(
                    userMessage: userMessage,
                    context: context,
                    conversationHistory: conversationHistory
                )
                
                // Add assistant response
                await MainActor.run {
                    var updatedMessages = messages
                    updatedMessages.append(ChatMessage(role: .assistant, content: response))
                    messages = updatedMessages
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
    
    private func buildConversationHistory() -> [GeminiMessage] {
        // Convert ChatMessage array to GeminiMessage array for API
        // Skip the welcome message (first assistant message) and only include actual conversation
        var history: [GeminiMessage] = []
        
        for message in messages {
            // Skip welcome messages (they're not part of the conversation context)
            if message.role == .assistant && message.content.contains("I have access to") {
                continue
            }
            
            let geminiRole = message.role == .user ? "user" : "model"
            let geminiMessage = GeminiMessage(
                role: geminiRole,
                parts: [GeminiPart(text: message.content)]
            )
            history.append(geminiMessage)
        }
        
        // Remove the last message (current user message) as it will be added separately
        if let lastMessage = history.last, lastMessage.role == "user" {
            history.removeLast()
        }
        
        return history
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
                
                // Render markdown content
                markdownText(message.content)
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
    
    @ViewBuilder
    private func markdownText(_ content: String) -> some View {
        // Convert HTML to markdown if needed, then render as markdown
        let markdownContent = convertHTMLToMarkdown(content)
        
        // SwiftUI Text supports markdown in macOS 12+
        // Preserve newlines by using MarkdownParsingOptions
        if let attributedString = try? createAttributedString(from: markdownContent) {
            Text(attributedString)
                .lineSpacing(4)
        } else {
            // Fallback: preserve newlines by splitting into lines
            fallbackTextWithNewlines(markdownContent)
        }
    }
    
    private func createAttributedString(from markdown: String) throws -> AttributedString {
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .inlineOnlyPreservingWhitespace
        return try AttributedString(markdown: markdown, options: options)
    }
    
    @ViewBuilder
    private func fallbackTextWithNewlines(_ content: String) -> some View {
        let lines = content.components(separatedBy: .newlines)
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                if !line.isEmpty || (index < lines.count - 1 && lines[index + 1].isEmpty) {
                    Text(line.isEmpty ? " " : line)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if line.isEmpty && index < lines.count - 1 {
                    // Preserve empty lines
                    Text(" ")
                        .frame(height: 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    private func convertHTMLToMarkdown(_ html: String) -> String {
        var markdown = html
        
        // Convert common HTML tags to markdown
        // Headers
        markdown = markdown.replacingOccurrences(of: "<h1>", with: "# ")
        markdown = markdown.replacingOccurrences(of: "</h1>", with: "\n\n")
        markdown = markdown.replacingOccurrences(of: "<h2>", with: "## ")
        markdown = markdown.replacingOccurrences(of: "</h2>", with: "\n\n")
        markdown = markdown.replacingOccurrences(of: "<h3>", with: "### ")
        markdown = markdown.replacingOccurrences(of: "</h3>", with: "\n\n")
        
        // Bold and italic
        markdown = markdown.replacingOccurrences(of: "<strong>", with: "**")
        markdown = markdown.replacingOccurrences(of: "</strong>", with: "**")
        markdown = markdown.replacingOccurrences(of: "<b>", with: "**")
        markdown = markdown.replacingOccurrences(of: "</b>", with: "**")
        markdown = markdown.replacingOccurrences(of: "<em>", with: "*")
        markdown = markdown.replacingOccurrences(of: "</em>", with: "*")
        markdown = markdown.replacingOccurrences(of: "<i>", with: "*")
        markdown = markdown.replacingOccurrences(of: "</i>", with: "*")
        
        // Code blocks
        markdown = markdown.replacingOccurrences(of: "<code>", with: "`")
        markdown = markdown.replacingOccurrences(of: "</code>", with: "`")
        markdown = markdown.replacingOccurrences(of: "<pre>", with: "```\n")
        markdown = markdown.replacingOccurrences(of: "</pre>", with: "\n```")
        
        // Lists
        markdown = markdown.replacingOccurrences(of: "<ul>", with: "")
        markdown = markdown.replacingOccurrences(of: "</ul>", with: "\n")
        markdown = markdown.replacingOccurrences(of: "<ol>", with: "")
        markdown = markdown.replacingOccurrences(of: "</ol>", with: "\n")
        markdown = markdown.replacingOccurrences(of: "<li>", with: "- ")
        markdown = markdown.replacingOccurrences(of: "</li>", with: "\n")
        
        // Paragraphs and line breaks
        markdown = markdown.replacingOccurrences(of: "<p>", with: "")
        markdown = markdown.replacingOccurrences(of: "</p>", with: "\n\n")
        markdown = markdown.replacingOccurrences(of: "<br>", with: "\n")
        markdown = markdown.replacingOccurrences(of: "<br/>", with: "\n")
        markdown = markdown.replacingOccurrences(of: "<br />", with: "\n")
        
        // Links
        markdown = markdown.replacingOccurrences(
            of: "<a href=\"([^\"]+)\">([^<]+)</a>",
            with: "[$2]($1)",
            options: .regularExpression
        )
        
        // Remove any remaining HTML tags
        markdown = markdown.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
        
        // Clean up extra whitespace
        markdown = markdown.replacingOccurrences(of: "\n\n\n+", with: "\n\n", options: .regularExpression)
        
        return markdown.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
