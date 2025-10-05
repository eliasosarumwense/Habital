//
//  DataExportImportView.swift
//  Habital
//
//  Created by Elias Osarumwense on 10.04.25.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

extension String {
    var containsEmoji: Bool {
        return self.contains { $0.isEmoji }
    }
    
    var isEmojiOnly: Bool {
        return self.count == 1 && self.first!.isEmoji
    }
}

// MARK: - CSV Handling Structure
struct DataExportImportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportData: Data?
    @State private var showExportAlert = false
    @State private var showImportAlert = false
    @State private var alertMessage = ""
    @State private var csvContent: String = ""
    @State private var debugLog = ""
    
    var body: some View {
        Form {
            Section(header: Text("Data Management")) {
                Button(action: {
                    exportData = createCSVData()
                    if exportData != nil {
                        isExporting = true
                    } else {
                        alertMessage = "Failed to create export data."
                        showExportAlert = true
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.up.doc")
                            .foregroundColor(.blue)
                        Text("Export Data as CSV")
                    }
                }
                
                Button(action: {
                    isImporting = true
                }) {
                    HStack {
                        Image(systemName: "arrow.down.doc")
                            .foregroundColor(.green)
                        Text("Import Data from CSV")
                    }
                }
            }
            
            // If we have CSV content, show a summary and import button
            if !csvContent.isEmpty {
                Section(header: Text("CSV Data Summary")) {
                    // Count habit lists and habits in the CSV
                    let counts = countEntitiesInCSV(csvContent)
                    
                    HStack {
                        Text("Lists:")
                        Spacer()
                        Text("\(counts.lists)")
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("Habits:")
                        Spacer()
                        Text("\(counts.habits)")
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("Repeat Patterns:")
                        Spacer()
                        Text("\(counts.repeatPatterns)")
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("Completions:")
                        Spacer()
                        Text("\(counts.completions)")
                            .fontWeight(.bold)
                    }
                    
                    Button("Process This Data") {
                        do {
                            try processCSVData(csvContent)
                            alertMessage = "Data imported successfully!"
                            showImportAlert = true
                        } catch {
                            debugLog += "\nError: \(error.localizedDescription)"
                            alertMessage = "Import failed: \(error.localizedDescription)"
                            showImportAlert = true
                        }
                    }
                    .foregroundColor(.blue)
                    .padding(.top, 8)
                }
            }
            
            // Debug log section
            if !debugLog.isEmpty {
                Section(header: Text("Debug Log")) {
                    Text(debugLog)
                        .font(.system(.caption, design: .monospaced))
                }
            }
        }
        .navigationTitle("Data Export & Import")
        .fileExporter(
            isPresented: $isExporting,
            document: CSVDocument(data: exportData ?? Data()),
            contentType: .commaSeparatedText,
            defaultFilename: "habital_export_\(formattedDate()).csv"
        ) { result in
            switch result {
            case .success(let url):
                alertMessage = "Data successfully exported to \(url.lastPathComponent)"
                showExportAlert = true
            case .failure(let error):
                alertMessage = "Export failed: \(error.localizedDescription)"
                showExportAlert = true
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else {
                    alertMessage = "No file selected."
                    showImportAlert = true
                    return
                }
                
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    do {
                        let data = try Data(contentsOf: url)
                        if let string = String(data: data, encoding: .utf8) {
                            debugLog = "Read CSV: \(string.count) bytes"
                            // Show first 200 chars
                            if string.count > 0 {
                                debugLog += "\nFirst line: \(string.split(separator: "\n").first ?? "")"
                            }
                            // Instead of processing immediately, just save the content and show preview
                            csvContent = string
                        } else {
                            alertMessage = "Could not read CSV data."
                            showImportAlert = true
                        }
                    } catch {
                        alertMessage = "Reading file failed: \(error.localizedDescription)"
                        showImportAlert = true
                    }
                } else {
                    alertMessage = "Could not access file."
                    showImportAlert = true
                }
                
            case .failure(let error):
                alertMessage = "Import failed: \(error.localizedDescription)"
                showImportAlert = true
            }
        }
        .alert(isPresented: $showExportAlert) {
            Alert(
                title: Text("Export Status"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert("Import Status", isPresented: $showImportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // This function converts emoji to a URI percent-encoded string which is safer for CSV
    private func safeEncodeIcon(_ icon: String?) -> String {
        guard let icon = icon, !icon.isEmpty else { return "" }
        
        // Check if it's likely an emoji (single character or contains emoji character)
        if icon.count == 1 || icon.contains(where: { $0.isEmoji }) {
            // Percent encode the icon (this safely preserves all Unicode characters)
            if let encoded = icon.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                return "URI:" + encoded
            }
        }
        
        // Regular SF Symbol name, return as is
        return icon
    }

    // This function decodes the URI percent-encoded emoji back to normal
    private func safeDecodeIcon(_ encoded: String) -> String? {
        if encoded.isEmpty {
            return nil
        }
        
        // Check if it's our URI-encoded format
        if encoded.hasPrefix("URI:") {
            let encodedPart = String(encoded.dropFirst(4))
            
            // Decode the percent-encoded string
            if let decoded = encodedPart.removingPercentEncoding {
                return decoded
            }
            
            // If decoding fails, return the encoded part without the prefix
            return encodedPart
        }
        
        // Regular string (likely an SF Symbol name)
        return encoded
    }
    
    // Create CSV data from the Core Data store
    private func createCSVData() -> Data? {
        // CSV Headers - Including all fields for our model
        var csvString = "Type,ID,Name,Description,Color,Icon,IsBadHabit,IsArchived,Order,StartDate,LastCompletionDate,RepeatPatternID,FollowUp,EffectiveFrom,CreationDate,RepeatsPerDay,GoalType,DailyGoalPattern,DaysInterval,SpecificDaysDaily,WeeklyGoalPattern,WeekInterval,SpecificDaysWeekly,MonthlyGoalPattern,MonthInterval,SpecificDaysMonthly,HabitListID,HabitListName,CompletionDate,CompletionDuration,CompletionStatus\n"
        
        // Fetch all habit lists
        let habitListRequest = HabitList.fetchRequest()
        
        do {
            let habitLists = try viewContext.fetch(habitListRequest)
            debugLog += "Found \(habitLists.count) habit lists to export\n"
            
            if habitLists.isEmpty && !hasStandaloneHabits() {
                // Return a test data row for debugging if no real data exists
                csvString += "HabitList,00000000-0000-0000-0000-000000000001,Test List,,,,,,,0,,,,,,,,,,,,,,,,,\n"
                csvString += "Habit,00000000-0000-0000-0000-000000000002,Test Habit,Test description,,icon.circle,false,false,0,,,00000000-0000-0000-0000-000000000003,false,,,1,daily,everyday,0,,,,,,,,,00000000-0000-0000-0000-000000000001,Test List,,,\n"
                csvString += "RepeatPattern,00000000-0000-0000-0000-000000000003,,,,,,,,,,,false,,,1,daily,everyday,0,,,,,,,,,,,,,\n"
                return csvString.data(using: .utf8)
            }
            
            // First, export all HabitLists
            for habitList in habitLists {
                guard let habitListID = habitList.id?.uuidString else {
                    debugLog += "Skipping habit list with nil ID\n"
                    continue
                }
                
                let habitListName = habitList.name ?? "Unnamed List"
                
                // Add habit list entries
                csvString += "HabitList,"
                csvString += "\(habitListID),"
                csvString += "\(escapeCsvField(habitListName)),"
                csvString += "," // No description for habit list
                
                // Color
                let colorString = habitList.color != nil ? Data(habitList.color!).base64EncodedString() : ""
                csvString += "\(colorString),"
                
                // Icon for habit list
                let listIconString = safeEncodeIcon(habitList.icon)
                csvString += "\(escapeCsvField(listIconString)),"
                
                // No isBadHabit, isArchived for habit list
                csvString += ",,"
                
                // Order
                csvString += "\(habitList.order),"
                
                // No start date, lastCompletionDate, repeatPatternID, followUp, effectiveFrom, etc. for habit lists
                csvString += ",,,,,,,,,,,,,,,,,,\n"
                
                // Now add all habits for this habit list
                if let habits = habitList.habits as? Set<Habit> {
                    debugLog += "Exporting \(habits.count) habits for list: \(habitListName)\n"
                    for habit in habits {
                        exportHabitToCSV(habit, habitListID: habitListID, habitListName: habitListName, csvString: &csvString)
                    }
                }
            }
            
            // Fetch any standalone habits (not in a list)
            let standAloneHabitRequest = Habit.fetchRequest()
            standAloneHabitRequest.predicate = NSPredicate(format: "habitList == nil")
            
            do {
                let standAloneHabits = try viewContext.fetch(standAloneHabitRequest)
                debugLog += "Found \(standAloneHabits.count) standalone habits to export\n"
                
                for habit in standAloneHabits {
                    exportHabitToCSV(habit, habitListID: nil, habitListName: nil, csvString: &csvString)
                }
            } catch {
                debugLog += "Error fetching standalone habits: \(error)\n"
            }
            
            debugLog += "CSV data created: \(csvString.count) bytes\n"
            return csvString.data(using: .utf8)
        } catch {
            debugLog += "Error fetching data: \(error)\n"
            return nil
        }
    }

    // Helper method to check if there are any standalone habits
    private func hasStandaloneHabits() -> Bool {
        let standAloneHabitRequest = Habit.fetchRequest()
        standAloneHabitRequest.predicate = NSPredicate(format: "habitList == nil")
        
        do {
            let standAloneHabits = try viewContext.fetch(standAloneHabitRequest)
            return !standAloneHabits.isEmpty
        } catch {
            return false
        }
    }

    // Helper method to export a habit and its associated data to CSV format
    private func exportHabitToCSV(_ habit: Habit, habitListID: String?, habitListName: String?, csvString: inout String) {
        guard let habitID = habit.id?.uuidString else {
            debugLog += "Skipping habit with nil ID\n"
            return
        }
        
        let habitName = habit.name ?? "Unnamed Habit"
        
        // Export habit base information
        csvString += "Habit,"
        csvString += "\(habitID),"
        csvString += "\(escapeCsvField(habitName)),"
        csvString += "\(escapeCsvField(habit.habitDescription ?? "")),"
        
        // Color
        let habitColorString = habit.color != nil ? Data(habit.color!).base64EncodedString() : ""
        csvString += "\(habitColorString),"
        
        // Icon - Safely encode emoji icons
        let iconString = safeEncodeIcon(habit.icon)
        csvString += "\(escapeCsvField(iconString)),"
        
        // Is bad habit, is archived
        csvString += "\(habit.isBadHabit),"
        csvString += "\(habit.isArchived),"
        
        // Order
        csvString += "\(habit.order),"
        
        // Start date
        let startDateString = habit.startDate != nil ? dateToString(habit.startDate!) : ""
        csvString += "\(startDateString),"
        
        // Last completion date
        let lastCompletionDateString = habit.lastCompletionDate != nil ? dateToString(habit.lastCompletionDate!) : ""
        csvString += "\(lastCompletionDateString),"
        
        // Initially empty RepeatPatternID placeholder - will be filled with first repeat pattern if available
        csvString += ","
        
        // Empty placeholders for repeat pattern fields
        csvString += ",,,,"
        
        // Empty placeholders for goal type fields
        csvString += ",,,,,,,,,"
        
        // Habit list reference
        if let habitListID = habitListID, let habitListName = habitListName {
            csvString += "\(habitListID),"
            csvString += "\(escapeCsvField(habitListName)),"
        } else {
            csvString += ",," // Empty list reference for standalone habits
        }
        
        // No completion data yet
        csvString += ",,\n"
        
        // Export all repeat patterns for this habit
        if let repeatPatterns = habit.repeatPattern as? Set<RepeatPattern> {
            debugLog += "  Exporting \(repeatPatterns.count) repeat patterns for habit: \(habitName)\n"
            
            for repeatPattern in repeatPatterns {
                exportRepeatPatternToCSV(repeatPattern, habitID: habitID, habitName: habitName, csvString: &csvString)
            }
        }
        
        // Export all completions for this habit
        if let completions = habit.completion as? Set<Completion> {
            debugLog += "  Exporting \(completions.count) completions for habit: \(habitName)\n"
            
            for completion in completions {
                exportCompletionToCSV(completion, habitID: habitID, habitName: habitName, csvString: &csvString)
            }
        }
    }
    
    // Helper method to export a repeat pattern to CSV format
    private func exportRepeatPatternToCSV(_ repeatPattern: RepeatPattern, habitID: String, habitName: String, csvString: inout String) {
        // Generate ID for the repeat pattern if it doesn't exist
        let repeatPatternID = UUID().uuidString
        
        // Export basic repeat pattern information
        csvString += "RepeatPattern,"
        csvString += "\(repeatPatternID)," // Use the generated ID
        csvString += "\(escapeCsvField(habitName))," // Include habit name for reference
        csvString += ",,," // No description, color, icon
        
        // No isBadHabit, isArchived, order, startDate, lastCompletionDate
        csvString += ",,,,,"
        
        // Add RepeatPattern reference to Habit ID
        csvString += "\(habitID),"
        
        // RepeatPattern specific fields
        csvString += "\(repeatPattern.followUp),"
        
        // EffectiveFrom date
        let effectiveFromString = repeatPattern.effectiveFrom != nil ? dateToString(repeatPattern.effectiveFrom!) : ""
        csvString += "\(effectiveFromString),"
        
        // Creation date
        let creationDateString = repeatPattern.creationDate != nil ? dateToString(repeatPattern.creationDate!) : ""
        csvString += "\(creationDateString),"
        
        // Repeats per day
        csvString += "\(repeatPattern.repeatsPerDay),"
        
        // Determine goal type and pattern details
        var goalType = ""
        var dailyGoalPattern = ""
        var daysInterval = "0"
        var specificDaysDaily = ""
        var weeklyGoalPattern = ""
        var weekInterval = "0"
        var specificDaysWeekly = ""
        var monthlyGoalPattern = ""
        var monthInterval = "0"
        var specificDaysMonthly = ""
        
        // Determine the goal type and specific fields
        if let dailyGoal = repeatPattern.dailyGoal {
            goalType = "daily"
            
            if dailyGoal.everyDay {
                dailyGoalPattern = "everyday"
            } else if dailyGoal.daysInterval > 0 {
                dailyGoalPattern = "everyXDays"
                daysInterval = "\(dailyGoal.daysInterval)"
            } else {
                dailyGoalPattern = "specificDays"
            }
            
            // Encode specific days as pipe-separated booleans
            if let specificDays = dailyGoal.specificDays as? [Bool] {
                specificDaysDaily = specificDays.map { "\($0)" }.joined(separator: "|")
            }
        } else if let weeklyGoal = repeatPattern.weeklyGoal {
            goalType = "weekly"
            
            if weeklyGoal.everyWeek {
                weeklyGoalPattern = "everyWeek"
            } else {
                weeklyGoalPattern = "weekInterval"
                weekInterval = "\(weeklyGoal.weekInterval)"
            }
            
            // Encode specific days as pipe-separated booleans
            if let specificDays = weeklyGoal.specificDays as? [Bool] {
                specificDaysWeekly = specificDays.map { "\($0)" }.joined(separator: "|")
            }
        } else if let monthlyGoal = repeatPattern.monthlyGoal {
            goalType = "monthly"
            
            if monthlyGoal.everyMonth {
                monthlyGoalPattern = "everyMonth"
            } else {
                monthlyGoalPattern = "monthInterval"
                monthInterval = "\(monthlyGoal.monthInterval)"
            }
            
            // Encode specific days as pipe-separated booleans
            if let specificDays = monthlyGoal.specificDays as? [Bool] {
                specificDaysMonthly = specificDays.map { "\($0)" }.joined(separator: "|")
            }
        }
        
        // Add goal type and specific fields
        csvString += "\(goalType),"
        csvString += "\(dailyGoalPattern),"
        csvString += "\(daysInterval),"
        csvString += "\(escapeCsvField(specificDaysDaily)),"
        csvString += "\(weeklyGoalPattern),"
        csvString += "\(weekInterval),"
        csvString += "\(escapeCsvField(specificDaysWeekly)),"
        csvString += "\(monthlyGoalPattern),"
        csvString += "\(monthInterval),"
        csvString += "\(escapeCsvField(specificDaysMonthly)),"
        
        // No habit list reference for repeat patterns
        csvString += ",,"
        
        // No completion data
        csvString += ",,\n"
    }
    
    // Helper method to export a completion to CSV format
    private func exportCompletionToCSV(_ completion: Completion, habitID: String, habitName: String, csvString: inout String) {
        guard let completionDate = completion.date else {
            debugLog += "  Skipping completion with nil date\n"
            return
        }
        
        // Export basic completion information
        csvString += "Completion,"
        csvString += "\(habitID)," // Use the habit ID as reference
        csvString += "\(escapeCsvField(habitName))," // Habit name for reference
        csvString += ",,,,,,," // No description, color, icon, isBadHabit, isArchived, order
        
        // No start date or last completion date for completions
        csvString += ",,"
        
        // No repeat pattern reference
        csvString += ","
        
        // No repeat pattern fields
        csvString += ",,,,,"
        
        // No goal type fields
        csvString += ",,,,,,,,,"
        
        // No habit list reference
        csvString += ",,"
        
        // Completion specific fields - Make sure the date goes in the CompletionDate column (28)
        csvString += "\(dateToString(completionDate))," // Field 28: CompletionDate
        csvString += "\(completion.duration)," // Field 29: CompletionDuration
        csvString += "\(completion.completed)\n" // Field 30: CompletionStatus
    }
    
    // Count entities in CSV
    private func countEntitiesInCSV(_ csvString: String) -> (lists: Int, habits: Int, repeatPatterns: Int, completions: Int) {
        var listCount = 0
        var habitCount = 0
        var repeatPatternCount = 0
        var completionCount = 0
        
        let lines = csvString.components(separatedBy: .newlines)
        
        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            
            let fields = parseCSVLine(line)
            guard !fields.isEmpty else { continue }
            
            let type = fields[0]
            
            switch type {
            case "HabitList":
                listCount += 1
            case "Habit":
                habitCount += 1
            case "RepeatPattern":
                repeatPatternCount += 1
            case "Completion":
                completionCount += 1
            default:
                break
            }
        }
        
        return (listCount, habitCount, repeatPatternCount, completionCount)
    }
    
    private func processCSVData(_ csvString: String) throws {
        debugLog = "Processing CSV: \(csvString.count) bytes"
        
        let lines = csvString.components(separatedBy: .newlines)
        
        // Skip the header line and ensure we have data
        guard lines.count > 1 else {
            debugLog += "\nError: CSV has no data rows"
            throw NSError(domain: "ImportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "CSV has no data rows"])
        }
        
        // Print some debug info
        debugLog += "\nHeader: \(lines[0])"
        if lines.count > 1 {
            debugLog += "\nFirst data row: \(lines[1])"
        }
        
        // Create dictionaries to store created objects
        var habitLists: [String: HabitList] = [:]
        var habits: [String: Habit] = [:]
        var repeatPatterns: [String: RepeatPattern] = [:]
        
        // STEP 1: Process HabitLists
        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            
            let fields = parseCSVLine(line)
            guard fields.count >= 6 else { continue } // Need at least type, id, name, desc, color, icon
            
            let type = fields[0]
            let id = fields[1]
            
            if type == "HabitList" {
                // Add to debug log
                debugLog += "\nProcessing HabitList: ID=\(id), Name=\(fields[2])"
                
                // Check if valid UUID
                guard let uuid = UUID(uuidString: id) else {
                    debugLog += " - Invalid UUID format"
                    continue
                }
                
                // Look for existing list
                let fetchRequest: NSFetchRequest<HabitList> = HabitList.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
                
                do {
                    let results = try viewContext.fetch(fetchRequest)
                    let habitList: HabitList
                    
                    if let existing = results.first {
                        debugLog += " - Found existing"
                        habitList = existing
                    } else {
                        debugLog += " - Creating new"
                        habitList = HabitList(context: viewContext)
                        habitList.id = uuid
                    }
                    
                    // Update properties
                    habitList.name = fields[2]
                    
                    if fields.count > 4 && !fields[4].isEmpty {
                        if let colorData = Data(base64Encoded: fields[4]) {
                            habitList.color = colorData
                        }
                    }
                    
                    // Process icon field for HabitList
                    if fields.count > 5 && !fields[5].isEmpty {
                        habitList.icon = safeDecodeIcon(fields[5])
                        debugLog += " - Icon: \(habitList.icon ?? "nil")"
                    }
                    
                    if fields.count > 8 {
                        habitList.order = Int16(fields[8]) ?? 0
                    }
                    
                    // Store in dictionary
                    habitLists[id] = habitList
                } catch {
                    debugLog += " - Error: \(error.localizedDescription)"
                }
            }
        }
        
        // Save after creating lists
        do {
            try viewContext.save()
            debugLog += "\nSaved \(habitLists.count) habit lists"
        } catch {
            debugLog += "\nError saving habit lists: \(error.localizedDescription)"
            throw error
        }
        
        // STEP 2: Process Habits
        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            
            let fields = parseCSVLine(line)
            
            // Check if we have enough fields
            guard fields.count >= 25 else {
                debugLog += "\nSkipping line with insufficient fields: \(fields.count)"
                continue
            }
            
            let type = fields[0]
            let id = fields[1]
            
            if type == "Habit" {
                // Add to debug log
                debugLog += "\nProcessing Habit: ID=\(id), Name=\(fields[2])"
                
                // Check if valid UUID
                guard let uuid = UUID(uuidString: id) else {
                    debugLog += " - Invalid UUID format"
                    continue
                }
                
                // Get habit list ID (can be empty for standalone habits)
                var habitList: HabitList? = nil
                if fields.count > 26 && !fields[26].isEmpty {
                    let habitListID = fields[26]
                    habitList = habitLists[habitListID]
                    if habitList == nil {
                        debugLog += " - Warning: Habit list not found: \(habitListID), will create standalone habit"
                    } else {
                        debugLog += " - Found habit list: \(habitList?.name ?? "unnamed")"
                    }
                } else {
                    debugLog += " - No habit list ID, creating standalone habit"
                }
                
                // Look for existing habit
                let fetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
                
                do {
                    let results = try viewContext.fetch(fetchRequest)
                    let habit: Habit
                    
                    if let existing = results.first {
                        debugLog += " - Found existing habit"
                        habit = existing
                    } else {
                        debugLog += " - Creating new habit"
                        habit = Habit(context: viewContext)
                        habit.id = uuid
                    }
                    
                    // Update properties
                    habit.name = fields[2]
                    habit.habitDescription = fields[3]
                    
                    if !fields[4].isEmpty {
                        if let colorData = Data(base64Encoded: fields[4]) {
                            habit.color = colorData
                        }
                    }
                    
                    // Icon - Safely decode emoji icons
                    let iconField = fields[5]
                    habit.icon = safeDecodeIcon(iconField)
                    debugLog += "\n - Processed icon: \(iconField) -> \(habit.icon ?? "nil")"
                    
                    habit.isBadHabit = Bool(fields[6]) ?? false
                    habit.isArchived = Bool(fields[7]) ?? false
                    habit.order = Int16(fields[8]) ?? 0
                    
                    // Dates
                    if !fields[9].isEmpty {
                        habit.startDate = stringToDate(fields[9])
                    }
                    
                    if !fields[10].isEmpty {
                        habit.lastCompletionDate = stringToDate(fields[10])
                    }
                    
                    // Link to habit list (if one was found)
                    habit.habitList = habitList
                    
                    // Update the habit list's habits set (only if a list exists)
                    if let habitList = habitList {
                        if habitList.habits == nil {
                            habitList.habits = NSSet(object: habit)
                        } else {
                            let mutableHabits = NSMutableSet(set: habitList.habits!)
                            mutableHabits.add(habit)
                            habitList.habits = mutableHabits
                        }
                    }
                    
                    // Store in dictionary for later use
                    habits[id] = habit
                } catch {
                    debugLog += "\n - Error processing habit: \(error.localizedDescription)"
                }
            }
        }
        
        // Save after creating habits
        do {
            try viewContext.save()
            debugLog += "\nSaved \(habits.count) habits"
        } catch {
            debugLog += "\nError saving habits: \(error.localizedDescription)"
            throw error
        }
        
        // STEP 3: Process RepeatPatterns
        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            
            let fields = parseCSVLine(line)
            guard fields.count >= 25 else { continue }
            
            let type = fields[0]
            let id = fields[1]
            
            if type == "RepeatPattern" {
                debugLog += "\nProcessing RepeatPattern: ID=\(id)"
                
                // Get habit ID - this is crucial for linking the repeat pattern to its habit
                guard fields.count > 11 && !fields[11].isEmpty else {
                    debugLog += " - Missing habit ID, skipping"
                    continue
                }
                
                let habitID = fields[11]
                guard let habit = habits[habitID] else {
                    debugLog += " - Habit not found with ID: \(habitID), skipping"
                    continue
                }
                
                // Create a new RepeatPattern
                let repeatPattern = RepeatPattern(context: viewContext)
                
                // Set basic properties
                repeatPattern.followUp = Bool(fields[12]) ?? false
                
                // EffectiveFrom date
                if !fields[13].isEmpty {
                    repeatPattern.effectiveFrom = stringToDate(fields[13])
                }
                
                // Creation date
                if !fields[14].isEmpty {
                    repeatPattern.creationDate = stringToDate(fields[14])
                } else {
                    repeatPattern.creationDate = Date() // Default to current date if missing
                }
                
                // Repeats per day
                if fields.count > 15 && !fields[15].isEmpty {
                    repeatPattern.repeatsPerDay = Int16(fields[15]) ?? 1
                } else {
                    repeatPattern.repeatsPerDay = 1 // Default to 1 if missing
                }
                
                // Link to the habit
                repeatPattern.habit = habit
                
                // Create the appropriate goal entity based on goal type
                let goalType = fields.count > 16 ? fields[16] : ""
                
                switch goalType {
                case "daily":
                    let dailyGoal = DailyGoal(context: viewContext)
                    let dailyGoalPattern = fields.count > 17 ? fields[17] : ""
                    
                    switch dailyGoalPattern {
                    case "everyday":
                        dailyGoal.everyDay = true
                    case "everyXDays":
                        if fields.count > 18 && !fields[18].isEmpty {
                            dailyGoal.daysInterval = Int16(fields[18]) ?? 1
                        } else {
                            dailyGoal.daysInterval = 1
                        }
                    case "specificDays":
                        // Parse pipe-separated boolean values
                        if fields.count > 19 && !fields[19].isEmpty {
                            let boolStrings = fields[19].split(separator: "|")
                            var boolArray = [Bool](repeating: false, count: max(7, boolStrings.count))
                            
                            for (index, boolString) in boolStrings.enumerated() {
                                if index < boolArray.count {
                                    boolArray[index] = Bool(String(boolString)) ?? false
                                }
                            }
                            
                            dailyGoal.specificDays = boolArray as NSObject
                        }
                    default:
                        debugLog += "\n - Unknown daily goal pattern: \(dailyGoalPattern), using everyday"
                        dailyGoal.everyDay = true
                    }
                    
                    // Link between RepeatPattern and DailyGoal
                    dailyGoal.repeatPattern = repeatPattern
                    repeatPattern.dailyGoal = dailyGoal
                    
                case "weekly":
                    let weeklyGoal = WeeklyGoal(context: viewContext)
                    let weeklyGoalPattern = fields.count > 20 ? fields[20] : ""
                    
                    switch weeklyGoalPattern {
                    case "everyWeek":
                        weeklyGoal.everyWeek = true
                    case "weekInterval":
                        if fields.count > 21 && !fields[21].isEmpty {
                            weeklyGoal.weekInterval = Int16(fields[21]) ?? 1
                        } else {
                            weeklyGoal.weekInterval = 1
                        }
                    default:
                        debugLog += "\n - Unknown weekly goal pattern: \(weeklyGoalPattern), using everyWeek"
                        weeklyGoal.everyWeek = true
                    }
                    
                    // Parse pipe-separated boolean values for specific days
                    if fields.count > 22 && !fields[22].isEmpty {
                        let boolStrings = fields[22].split(separator: "|")
                        var boolArray = [Bool](repeating: false, count: 7)
                        
                        for (index, boolString) in boolStrings.enumerated() {
                            if index < 7 {
                                boolArray[index] = Bool(String(boolString)) ?? false
                            }
                        }
                        
                        weeklyGoal.specificDays = boolArray as NSObject
                    }
                    
                    // Link between RepeatPattern and WeeklyGoal
                    weeklyGoal.repeatPattern = repeatPattern
                    repeatPattern.weeklyGoal = weeklyGoal
                    
                case "monthly":
                    let monthlyGoal = MonthlyGoal(context: viewContext)
                    let monthlyGoalPattern = fields.count > 23 ? fields[23] : ""
                    
                    switch monthlyGoalPattern {
                    case "everyMonth":
                        monthlyGoal.everyMonth = true
                    case "monthInterval":
                        if fields.count > 24 && !fields[24].isEmpty {
                            monthlyGoal.monthInterval = Int16(fields[24]) ?? 1
                        } else {
                            monthlyGoal.monthInterval = 1
                        }
                    default:
                        debugLog += "\n - Unknown monthly goal pattern: \(monthlyGoalPattern), using everyMonth"
                        monthlyGoal.everyMonth = true
                    }
                    
                    // Parse pipe-separated boolean values for specific days
                    if fields.count > 25 && !fields[25].isEmpty {
                        let boolStrings = fields[25].split(separator: "|")
                        var boolArray = [Bool](repeating: false, count: 31)
                        
                        for (index, boolString) in boolStrings.enumerated() {
                            if index < 31 {
                                boolArray[index] = Bool(String(boolString)) ?? false
                            }
                        }
                        
                        monthlyGoal.specificDays = boolArray as NSObject
                    }
                    
                    // Link between RepeatPattern and MonthlyGoal
                    monthlyGoal.repeatPattern = repeatPattern
                    repeatPattern.monthlyGoal = monthlyGoal
                    
                default:
                    debugLog += "\n - Unknown goal type: \(goalType), skipping goal creation"
                }
                
                // Add this repeat pattern to the habit's repeatPattern set
                if habit.repeatPattern == nil {
                    habit.repeatPattern = NSSet(object: repeatPattern)
                } else {
                    let mutableSet = NSMutableSet(set: habit.repeatPattern!)
                    mutableSet.add(repeatPattern)
                    habit.repeatPattern = mutableSet
                }
                
                // Store in dictionary for later use
                repeatPatterns[id] = repeatPattern
            }
        }
        
        // Save after creating repeat patterns
        do {
            try viewContext.save()
            debugLog += "\nSaved \(repeatPatterns.count) repeat patterns"
        } catch {
            debugLog += "\nError saving repeat patterns: \(error.localizedDescription)"
            throw error
        }
        
        // STEP 4: Process Completions
        var completionCount = 0
        debugLog += "\n\n--- PROCESSING COMPLETIONS ---"

        // First analyze the CSV structure to understand headers
        if lines.count > 0 {
            let headers = parseCSVLine(lines[0])
            debugLog += "\nCSV Headers:"
            for (i, header) in headers.enumerated() {
                debugLog += "\n  \(i): \(header)"
            }
            
            // Specifically look for completion-related header positions
            let dateHeaderIndex = headers.firstIndex(of: "CompletionDate")
            let durationHeaderIndex = headers.firstIndex(of: "CompletionDuration")
            let statusHeaderIndex = headers.firstIndex(of: "CompletionStatus")
            
            debugLog += "\nDetected header positions - Date: \(dateHeaderIndex ?? -1), Duration: \(durationHeaderIndex ?? -1), Status: \(statusHeaderIndex ?? -1)"
        }

        // Log a few completion rows for debugging
        let sampleCompletions = lines.filter { line in
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let fields = parseCSVLine(trimmedLine)
            return fields.count > 0 && fields[0] == "Completion"
        }.prefix(3)

        for (i, line) in sampleCompletions.enumerated() {
            let fields = parseCSVLine(line)
            debugLog += "\n\nSample Completion \(i+1): \(fields.count) fields"
            let lastFields = min(fields.count, 31)
            debugLog += "\nFields \(lastFields-3) to \(lastFields-1): \(fields[lastFields-3...lastFields-1])"
        }

        // Process each completion
        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            
            let fields = parseCSVLine(line)
            guard fields.count >= 5 else { continue }
            
            let type = fields[0]
            
            if type == "Completion" {
                // Get habit ID (field index 1)
                let habitID = fields[1]
                
                // Try to find the habit
                var habit: Habit? = habits[habitID]
                
                // If not found in dictionary, try Core Data directly
                if habit == nil {
                    guard let uuid = UUID(uuidString: habitID) else {
                        debugLog += "\nInvalid habit UUID format: \(habitID), skipping completion"
                        continue
                    }
                    
                    let habitFetch: NSFetchRequest<Habit> = Habit.fetchRequest()
                    habitFetch.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
                    
                    do {
                        let results = try viewContext.fetch(habitFetch)
                        habit = results.first
                    } catch {
                        debugLog += "\nError fetching habit by ID: \(error.localizedDescription)"
                    }
                }
                
                guard let habitForCompletion = habit else {
                    debugLog += "\nCompletion references unknown habit ID: \(habitID), skipping"
                    continue
                }
                
                // Look for CompletionDate in field 28 (assuming standard CSV format)
                var completionDate: Date?
                
                if fields.count > 28 && !fields[28].isEmpty {
                    completionDate = stringToDate(fields[28])
                    if completionDate != nil && completionCount < 5 {
                        debugLog += "\nFound date in field 28 (CompletionDate): \(fields[28])"
                    }
                }
                
                // If date not found in expected position, look through all fields
                if completionDate == nil {
                    for j in 0..<fields.count {
                        if !fields[j].isEmpty, let date = stringToDate(fields[j]) {
                            completionDate = date
                            if completionCount < 5 {
                                debugLog += "\nFound date in field \(j): \(fields[j])"
                            }
                            break
                        }
                    }
                }
                
                // If we still don't have a date, try using today's date as a fallback
                if completionDate == nil {
                    completionDate = Date()
                    debugLog += "\nNo date found for completion, using current date as fallback"
                    continue  // Skip this completion if no date found
                }
                
                // Check if this completion already exists
                let completionFetch: NSFetchRequest<Completion> = Completion.fetchRequest()
                let datePredicate = NSPredicate(format: "date == %@", completionDate! as NSDate)
                let habitPredicate = NSPredicate(format: "habit == %@", habitForCompletion)
                completionFetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, habitPredicate])
                
                do {
                    let existingCompletions = try viewContext.fetch(completionFetch)
                    if !existingCompletions.isEmpty {
                        debugLog += "\nCompletion already exists for habit \(habitForCompletion.name ?? "[unnamed]") on \(dateToString(completionDate!))"
                        continue
                    }
                    
                    // Create the completion
                    let completion = Completion(context: viewContext)
                    completion.date = completionDate
                    
                    // Get duration - should be in field 29
                    if fields.count > 29 && !fields[29].isEmpty {
                        if let duration = Int16(fields[29]) {
                            completion.duration = duration
                        }
                    }
                    
                    // Get completion status - should be in field 30
                    if fields.count > 30 && !fields[30].isEmpty {
                        if let status = Bool(fields[30]) {
                            completion.completed = status
                        } else {
                            completion.completed = true  // Default to true
                        }
                    } else {
                        completion.completed = true  // Default to true
                    }
                    
                    // Set the relationship using the explicit accessor method
                    completion.habit = habitForCompletion
                    habitForCompletion.addToCompletion(completion)
                    
                    // Save after each completion
                    try viewContext.save()
                    
                    completionCount += 1
                    
                    // Log for debugging
                    if completionCount <= 5 || completionCount % 20 == 0 {
                        debugLog += "\nCreated completion #\(completionCount) for habit '\(habitForCompletion.name ?? "[unnamed]")' on \(dateToString(completionDate!))"
                    }
                } catch {
                    debugLog += "\nError processing completion: \(error.localizedDescription)"
                }
            }
        }

        // Verify completion import
        do {
            let allCompletions = try viewContext.fetch(Completion.fetchRequest())
            let orphanedCompletions = allCompletions.filter { $0.habit == nil }
            
            debugLog += "\n\n--- COMPLETION IMPORT SUMMARY ---"
            debugLog += "\nTotal completions in database: \(allCompletions.count)"
            debugLog += "\nNewly imported completions: \(completionCount)"
            
            if !orphanedCompletions.isEmpty {
                debugLog += "\nWARNING: Found \(orphanedCompletions.count) completions not linked to any habit!"
            } else {
                debugLog += "\nAll completions are properly linked to habits ✓"
            }
        } catch {
            debugLog += "\nError verifying completions: \(error.localizedDescription)"
        }
        
        
        // Final validation for completions
        do {
            let allCompletions = try viewContext.fetch(Completion.fetchRequest())
            let orphanedCompletions = allCompletions.filter { $0.habit == nil }
            
            if !orphanedCompletions.isEmpty {
                debugLog += "\n\nWARNING: Found \(orphanedCompletions.count) completions not linked to any habit!"
                
                // Try to fix orphaned completions
                for completion in orphanedCompletions {
                    if let date = completion.date {
                        debugLog += "\n  Orphaned completion on date: \(dateToString(date))"
                    }
                }
            } else {
                debugLog += "\n\nAll completions are properly linked to habits."
            }
        } catch {
            debugLog += "\nError checking for orphaned completions: \(error.localizedDescription)"
        }
        
        // Save after creating completions
        do {
            try viewContext.save()
            debugLog += "\nSaved \(completionCount) completions"
        } catch {
            debugLog += "\nError saving completions: \(error.localizedDescription)"
            throw error
        }
        
        // Final verification and summary
        do {
            let habitRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
            let allHabits = try viewContext.fetch(habitRequest)
            
            let repeatPatternRequest: NSFetchRequest<RepeatPattern> = RepeatPattern.fetchRequest()
            let allRepeatPatterns = try viewContext.fetch(repeatPatternRequest)
            
            let completionRequest: NSFetchRequest<Completion> = Completion.fetchRequest()
            let allCompletions = try viewContext.fetch(completionRequest)
            
            debugLog += "\n\n--- IMPORT SUMMARY ---"
            debugLog += "\nTotal Habit Lists: \(habitLists.count)"
            debugLog += "\nTotal Habits: \(allHabits.count)"
            debugLog += "\nTotal Repeat Patterns: \(allRepeatPatterns.count)"
            debugLog += "\nTotal Completions: \(allCompletions.count)"
            
            // Additional verification for relationships
            var habitsWithPatterns = 0
            var habitsWithCompletions = 0
            
            for habit in allHabits {
                if let patterns = habit.repeatPattern as? Set<RepeatPattern>, !patterns.isEmpty {
                    habitsWithPatterns += 1
                }
                
                if let completions = habit.completion as? Set<Completion>, !completions.isEmpty {
                    habitsWithCompletions += 1
                }
            }
            
            debugLog += "\nHabits with Repeat Patterns: \(habitsWithPatterns)"
            debugLog += "\nHabits with Completions: \(habitsWithCompletions)"
            
        } catch {
            debugLog += "\nVerification error: \(error.localizedDescription)"
        }
        
        // Notify that data was imported
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("DataImportedNotification"), object: nil)
        }
    }

    // Helper functions for date conversion
    private func dateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }

    private func stringToDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: string)
    }

    // Helper function to escape fields for CSV
    private func escapeCsvField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escapedField)\""
        }
        return field
    }

    // Helper function to parse CSV lines (handling quotes properly)
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false
        
        var i = 0
        let characters = Array(line)
        
        while i < characters.count {
            let char = characters[i]
            
            if char == "\"" {
                if inQuotes && i + 1 < characters.count && characters[i + 1] == "\"" {
                    // Escaped quote inside quotes
                    currentField.append("\"")
                    i += 2
                    continue
                }
                inQuotes = !inQuotes
            } else if char == "," && !inQuotes {
                // End of field
                fields.append(currentField)
                currentField = ""
            } else {
                // Normal character
                currentField.append(char)
            }
            
            i += 1
        }
        
        // Add the final field
        fields.append(currentField)
        return fields
    }
    
    // Helper function to format current date for filename
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
    

}
                        

