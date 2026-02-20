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
    
    enum CodingKeys: String, CodingKey {
        case contents
        case systemInstruction
    }
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
    // Using Gemini 3 models (latest available):
    // - gemini-3-flash-preview (fast, latest)
    // - gemini-3-pro-preview (more capable, latest)
    private let modelName = "gemini-3-flash-preview"
    private let apiVersion = "v1beta"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    private func buildRequestURL() -> URL? {
        // Format: https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={apiKey}
        let baseURLString = "https://generativelanguage.googleapis.com/\(apiVersion)/models/\(modelName):generateContent"
        var urlComponents = URLComponents(string: baseURLString)
        urlComponents?.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        return urlComponents?.url
    }
    
    // Helper to list available models (for debugging)
    func listAvailableModels() async throws -> [String] {
        let listURLString = "https://generativelanguage.googleapis.com/\(apiVersion)/models?key=\(apiKey)"
        guard let url = URL(string: listURLString) else {
            throw GeminiError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GeminiError.networkError("Failed to list models")
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let models = json["models"] as? [[String: Any]] {
            return models.compactMap { $0["name"] as? String }
        }
        
        return []
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
        guard let url = buildRequestURL() else {
            throw GeminiError.invalidResponse
        }
        
        // Create request
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Also include API key in header (some APIs prefer this)
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw GeminiError.invalidResponse
        }
        
        // Debug: Print request details
        print("🔍 Gemini API Request URL: \(url.absoluteString)")
        print("🔍 Request Method: \(urlRequest.httpMethod ?? "unknown")")
        if let body = urlRequest.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("🔍 Request Body: \(String(bodyString.prefix(500)))...")
        }
        
        // Send request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.networkError("Invalid response")
        }
        
        // Debug: Print response details
        print("🔍 Gemini API Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔍 Response Body: \(String(responseString.prefix(500)))...")
        }
        
        // Handle errors
        if httpResponse.statusCode == 400 {
            // Try to parse error details
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorData["error"] as? [String: Any],
               let message = errorMessage["message"] as? String {
                throw GeminiError.networkError("Bad Request: \(message)")
            }
            throw GeminiError.invalidAPIKey
        } else if httpResponse.statusCode == 401 {
            throw GeminiError.invalidAPIKey
        } else if httpResponse.statusCode == 404 {
            throw GeminiError.networkError("Endpoint not found (404). Check API URL and model name.")
        } else if httpResponse.statusCode == 429 {
            throw GeminiError.rateLimitExceeded
        } else if httpResponse.statusCode != 200 {
            if let responseString = String(data: data, encoding: .utf8) {
                throw GeminiError.networkError("HTTP \(httpResponse.statusCode): \(responseString)")
            }
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
