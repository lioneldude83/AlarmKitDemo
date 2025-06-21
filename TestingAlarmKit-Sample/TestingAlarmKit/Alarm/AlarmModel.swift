//
//  AlarmModel.swift
//  TestingAlarmKit
//
//  Created by Lionel Ng on 19/6/25.
//

import Foundation
import SwiftData

@Model
class AlarmModel: Identifiable {
    @Attribute(.unique) var id = UUID()
    var createdAt: Date?
    var duration: TimeInterval?
    var adjustedRemaining: TimeInterval?
    var label: String?
    
    init(id: UUID = UUID(), createdAt: Date? = nil, duration: TimeInterval? = nil, adjustedRemaining: TimeInterval? = nil, label: String? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.duration = duration
        self.adjustedRemaining = adjustedRemaining
        self.label = label
    }
}
