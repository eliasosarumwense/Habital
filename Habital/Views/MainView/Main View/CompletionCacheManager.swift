//
//  CompletionCacheManager.swift
//  Habital
//
//  Created by Assistant on 08.11.25.
//

import SwiftUI
import Combine

/// Manages completion cache invalidation across the app
/// Allows views to react to completion changes without full recreation
class CompletionCacheManager: ObservableObject {
    static let shared = CompletionCacheManager()
    
    /// Published property that triggers view updates when completions change
    @Published var lastCompletionUpdate: Date = Date()
    
    /// Trigger ID that changes whenever a completion is toggled
    @Published var completionTriggerID = UUID()
    
    private init() {}
    
    /// Call this when a habit completion is toggled
    func notifyCompletionChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.lastCompletionUpdate = Date()
            self?.completionTriggerID = UUID()
        }
    }
    
    /// Reset the manager (useful for testing or full refreshes)
    func reset() {
        lastCompletionUpdate = Date()
        completionTriggerID = UUID()
    }
}
