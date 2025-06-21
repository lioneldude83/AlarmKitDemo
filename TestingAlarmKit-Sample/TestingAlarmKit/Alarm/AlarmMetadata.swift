//
//  AlarmMetadata.swift
//  TestingAlarmKit
//
//  Created by Lionel Ng on 18/6/25.
//

import AlarmKit

// Build Settings -> Swift Compiler - Concurrency -> Default Actor -> nonisolated
// Set this struct to nonisolated → Allows it to run on any thread, not confined to a specific actor
// Sendable → Indicates the type is safe to pass between concurrency domains (e.g., tasks or actors)
nonisolated struct TimerData: AlarmMetadata {
    let createdAt: Date
    var duration: TimeInterval
    var adjustedRemaining: TimeInterval?
    let label: String?
    
    init(duration: TimeInterval, adjustedRemaining: TimeInterval? = nil, label: String? = nil) {
        self.createdAt = Date()
        self.duration = duration
        self.adjustedRemaining = adjustedRemaining
        self.label = label
    }
}
