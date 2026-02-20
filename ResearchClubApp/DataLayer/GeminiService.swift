//
//  GeminiService.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation

struct GeminiMessage: Codable {
    let role: String // "user" or "model"
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiRequest: Codable {
    let contents: [GeminiMessage]
    let systemInstruction: GeminiSystemInstruction?
}

struct GeminiSystemInstruction: Codable {
    let parts: [GeminiPart]
}

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
    let promptFeedback: GeminiPromptFeedback?
}

struct GeminiCandidate: Codable {
    let content: GeminiMessage
    let finishReason: String?
}

struct GeminiPromptFeedback: Codable {
    let blockReason: String?
}

enum GeminiError: LocalizedError {
    case invalidAPIKey
    case networkError(String)
    case invalidResponse
    case rateLimitExceeded
    case contentBlocked
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid Gemini API key"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from Gemini API"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .contentBlocked:
            return "Content was blocked by Gemini safety filters"
        }
    }
}

class GeminiService {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func sendMessage(
        userMessage: String,
        context: String,
        systemInstruction: String? = nil
    ) async throws -> String {
        // Build system instruction with context about the spreadsheets
        let systemPrompt = buildSystemPrompt(context: context, customInstruction: systemInstruction)
        
        // Combine context and user message into a single user message
        let combinedMessage = "\(systemPrompt)\n\nUser question: \(userMessage)"
        
        let userMsg = GeminiMessage(
            role: "user",
            parts: [GeminiPart(text: combinedMessage)]
        )
        
        let request = GeminiRequest(
            contents: [userMsg],
            systemInstruction: nil
        )
        
        // Build URL
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw GeminiError.invalidResponse
        }
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        
        guard let url = urlComponents.url else {
            throw GeminiError.invalidResponse
        }
        
        // Create request
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw GeminiError.invalidResponse
        }
        
        // Send request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.networkError("Invalid response")
        }
        
        // Handle errors
        if httpResponse.statusCode == 400 {
            throw GeminiError.invalidAPIKey
        } else if httpResponse.statusCode == 429 {
            throw GeminiError.rateLimitExceeded
        } else if httpResponse.statusCode != 200 {
            throw GeminiError.networkError("HTTP \(httpResponse.statusCode)")
        }
        
        // Parse response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let geminiResponse: GeminiResponse
        do {
            geminiResponse = try decoder.decode(GeminiResponse.self, from: data)
        } catch {
            // Debug: print raw response if decoding fails
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Gemini API Response: \(responseString)")
            }
            throw GeminiError.invalidResponse
        }
        
        // Check for blocked content
        if let blockReason = geminiResponse.promptFeedback?.blockReason {
            throw GeminiError.contentBlocked
        }
        
        // Extract response text
        guard let candidate = geminiResponse.candidates?.first,
              let text = candidate.content.parts.first?.text else {
            throw GeminiError.invalidResponse
        }
        
        return text
    }
    
    private func buildSystemPrompt(context: String, customInstruction: String?) -> String {
        var prompt = """
        You are a financial data analyst assistant. You have access to stock market data in CSV format.
        
        Available data:
        \(context)
        
        Please analyze this data and provide insights about:
        - Price trends and patterns
        - Volume analysis
        - Volatility indicators
        - Potential anomalies or unusual patterns
        - Correlations between different metrics
        
        Be specific and reference actual data points when possible. Format your response clearly with bullet points or numbered lists.
        """
        
        if let customInstruction = customInstruction {
            prompt += "\n\nAdditional instructions: \(customInstruction)"
        }
        
        return prompt
    }
}
