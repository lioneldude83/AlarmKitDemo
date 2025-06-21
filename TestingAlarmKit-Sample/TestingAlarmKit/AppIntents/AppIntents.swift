//
//  AppIntents.swift
//  TestingAlarmKit
//
//  Created by Lionel Ng on 19/6/25.
//

import AlarmKit
import AppIntents
import SwiftData

struct PauseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause"
    static var description: IntentDescription = "Pause a countdown"
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
    
    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else {
            throw NSError(domain: "Invalid UUID string", code: 0, userInfo: nil)
        }
        
        let schema = Schema([AlarmModel.self])
        let modelConfiguration = ModelConfiguration(schema: schema, allowsSave: true)
        
        guard let container = try? ModelContainer(for: schema, configurations: [modelConfiguration]) else {
            print("Pause Intent: Failed to load container")
            throw NSError(domain: "Failed to load container", code: 0, userInfo: nil)
        }
        
        let context = ModelContext(container)
        let predicate = #Predicate<AlarmModel> { $0.id == uuid }
        let descriptor = FetchDescriptor<AlarmModel>(predicate: predicate)
        
        guard let model = try context.fetch(descriptor).first else {
            print("Pause Intent: Failed to fetch alarm model")
            throw NSError(domain: "Failed to fetch alarm model", code: 0, userInfo: nil)
        }
        
        guard let createdAt = model.createdAt,
              let duration = model.duration else {
            print("Pause Intent: Invalid createdAt or duration")
            throw NSError(domain: "Invalid createdAt or duration", code: 0, userInfo: nil)
        }
        let elapsed = Date().timeIntervalSince(createdAt)
        let remaining = max(duration - elapsed, 0)
        model.adjustedRemaining = remaining
        
        try? context.save()
        print("Pause Intent: Alarm Model saved with adjustedRemaining: \(remaining)")
        
        try AlarmManager.shared.pause(id: uuid)
        return .result()
    }
}

struct StopIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop"
    static var description: IntentDescription = "Stop a countdown"
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
    
    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else {
            throw NSError(domain: "Invalid UUID string", code: 0, userInfo: nil)
        }
        
        try AlarmManager.shared.stop(id: uuid)
        return .result()
    }
}

struct ResumeIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume"
    static var description: IntentDescription = "Resume a countdown"
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
    
    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else {
            throw NSError(domain: "Invalid UUID string", code: 0, userInfo: nil)
        }
        
        let schema = Schema([AlarmModel.self])
        let modelConfiguration = ModelConfiguration(schema: schema, allowsSave: true)
        
        guard let container = try? ModelContainer(for: schema, configurations: [modelConfiguration]) else {
            print("Resume Intent: Failed to load container")
            throw NSError(domain: "Failed to load container", code: 0, userInfo: nil)
        }
        
        let context = ModelContext(container)
        let predicate = #Predicate<AlarmModel> { $0.id == uuid }
        let descriptor = FetchDescriptor<AlarmModel>(predicate: predicate)
        
        guard let model = try context.fetch(descriptor).first else {
            print("Resume Intent: Failed to fetch alarm model")
            throw NSError(domain: "Failed to fetch alarm model", code: 0, userInfo: nil)
        }
        
        guard let remaining = model.adjustedRemaining,
              let duration = model.duration else {
            print("Resume Intent: Invalid adjustedRemaining or duration")
            throw NSError(domain: "Invalid adjustedRemaining or duration", code: 0, userInfo: nil)
        }
        let elapsed = max(duration - remaining, 0)
        let newCreatedAt = Date().addingTimeInterval(-elapsed)
        model.createdAt = newCreatedAt
        model.adjustedRemaining = nil
        
        try? context.save()
        print("Resume Intent: Alarm Model saved with newly createdAt: \(newCreatedAt), duration: \(duration)")
        
        try AlarmManager.shared.resume(id: uuid)
        return .result()
    }
}

struct OpenAlarmAppIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Open App"
    static var description: IntentDescription = "Opens the App"
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
    
    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else {
            throw NSError(domain: "Invalid UUID string", code: 0, userInfo: nil)
        }
        
        try AlarmManager.shared.stop(id: uuid)
        return .result()
    }
}
