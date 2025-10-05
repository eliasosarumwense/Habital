//
//  CreateHabitChatGPTY.swift
//  Habital
//
//  Created by Elias Osarumwense on 09.06.25.
//

import Combine
import SwiftUI

// MARK: - Habit model from GPT response
/*
struct HabitResponse: Codable, Identifiable {
    let id = UUID()
    let name: String
    let habitDescription: String?
    let isBadHabit: Bool?
    let startDate: String
    let intensityLevel: Int?
    let repeatsPerDay: Int?  // NEW: Separate from intensity
    
    struct RepeatPattern: Codable {
        let type: String?
        let everyDay: Bool?
        let daily: Bool?
        let daysInterval: Int?
        let specificDays: [String]?
    }
    let repeatPattern: RepeatPattern?
}

// Wrapper for array of habits
struct HabitResponseWrapper: Codable {
    let habits: [HabitResponse]
}

// MARK: - ViewModel

// MARK: - Updated ViewModel with faster model

public class HabitViewModel: ObservableObject {
    @Published var userInput = ""
    @Published var habits: [HabitResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    
    
    func generateHabits() {
        guard !userInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        habits = []
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        let functionSchema: [String: Any] = [
            "name": "create_habit",
            "description": "Create specific, measurable habits",
            "parameters": [
                "type": "object",
                "properties": [
                    "habits": [
                        "type": "array",
                        "items": [
                            "type": "object",
                            "properties": [
                                "name": ["type": "string"],
                                "habitDescription": ["type": "string"],
                                "isBadHabit": ["type": "boolean"],
                                "startDate": ["type": "string", "format": "date"],
                                "intensityLevel": ["type": "integer", "minimum": 1, "maximum": 4],
                                "repeatsPerDay": ["type": "integer", "minimum": 1, "maximum": 10],
                                "repeatPattern": [
                                    "type": "object",
                                    "properties": [
                                        "type": ["type": "string", "enum": ["daily"]],
                                        "everyDay": ["type": "boolean"]
                                    ]
                                ]
                            ],
                            "required": ["name", "habitDescription", "isBadHabit", "startDate", "intensityLevel", "repeatsPerDay", "repeatPattern"]
                        ]
                    ]
                ],
                "required": ["habits"]
            ]
        ]
        
        // Even more concise prompt optimized for faster models
        let systemMessage = """
        Create 5 SNAPPY habits (2-4 words) solving user's problem.

        Format: {"habits": [{"name": "Walk 8K steps", "habitDescription": "Improves cardiovascular health", "isBadHabit": false, "startDate": "2025-06-12", "intensityLevel": 2, "repeatsPerDay": 1, "repeatPattern": {"type": "daily", "everyDay": true}}]}

        Rules:
        - name: 2-4 words, countable ("Read 20 pages", "Sleep by 10PM")
        - habitDescription: why it helps
        - intensityLevel: 1=Easy(5-15min), 2=Medium(15-30min), 3=Hard(30-60min), 4=Extreme(60min+)
        - repeatsPerDay: 1-10 times daily
        - isBadHabit: true only for stopping behaviors
        """

        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini", // Faster, lighter model
            "messages": [
                ["role": "system", "content": systemMessage],
                ["role": "user", "content": userInput]
            ],
            "functions": [functionSchema],
            "function_call": ["name": "create_habit"],
            "temperature": 0.8, // Lower for faster, more consistent responses
            "max_tokens": 1000   // Reduced for faster response
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            self.isLoading = false
            self.errorMessage = "Failed to serialize request."
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    if let error = json?["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        self.errorMessage = "API: \(message)"
                        return
                    }
                    
                    guard let choices = json?["choices"] as? [[String: Any]] else {
                        self.errorMessage = "Invalid response format"
                        return
                    }
                    
                    var habits: [HabitResponse] = []
                    
                    for choice in choices {
                        if let message = choice["message"] as? [String: Any],
                           let functionCall = message["function_call"] as? [String: Any],
                           let argumentsString = functionCall["arguments"] as? String,
                           let argsData = argumentsString.data(using: .utf8) {
                            
                            do {
                                let decodedWrapper = try JSONDecoder().decode(HabitResponseWrapper.self, from: argsData)
                                habits.append(contentsOf: decodedWrapper.habits)
                            } catch {
                                print("Decode error: \(error)")
                            }
                        }
                    }
                    
                    if habits.isEmpty {
                        self.errorMessage = "No habits generated. Try again."
                    } else {
                        self.habits = habits
                    }
                    
                } catch {
                    self.errorMessage = "Parse error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}
*/
