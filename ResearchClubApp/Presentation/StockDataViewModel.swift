//
//  StockDataViewModel.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation
import SwiftUI

@MainActor
class StockDataViewModel: ObservableObject {
    @Published var ticker: String = ""
    @Published var selectedDate: Date = {
        // Default to previous day
        Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    }()
    @Published var granularity: AggregateGranularity = .fiveMinutes // Default to 5 minutes
    @Published var aggregates: [StockAggregate] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var getStockAggregatesUseCase: GetStockAggregatesUseCase
    
    init(getStockAggregatesUseCase: GetStockAggregatesUseCase) {
        self.getStockAggregatesUseCase = getStockAggregatesUseCase
    }
    
    /// Convenience initializer that creates a use case from a repository
    /// This is useful for dependency injection at the app level
    convenience init(repository: any MassiveRepository) {
        let useCase = GetStockAggregatesUseCase(repository: repository)
        self.init(getStockAggregatesUseCase: useCase)
    }
    
    /// Updates the use case with a new repository
    /// This allows switching between mock and real repositories at runtime
    func updateRepository(_ repository: any MassiveRepository) {
        self.getStockAggregatesUseCase = GetStockAggregatesUseCase(repository: repository)
    }
    
    func fetchStockData() async {
        // Presentation logic: Basic UI validation
        guard !ticker.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a stock ticker"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Delegate to use case for business logic with selected granularity
            let fetchedAggregates = try await getStockAggregatesUseCase.execute(
                ticker: ticker,
                date: selectedDate,
                granularity: granularity
            )
            
            aggregates = fetchedAggregates
        } catch {
            // Presentation logic: Format error for display
            errorMessage = error.localizedDescription
            aggregates = []
        }
        
        isLoading = false
    }
}
