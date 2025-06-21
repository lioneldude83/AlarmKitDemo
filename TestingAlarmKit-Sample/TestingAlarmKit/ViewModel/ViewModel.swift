//
//  ViewModel.swift
//  TestingAlarmKit
//
//  Created by Lionel Ng on 19/6/25.
//

import AlarmKit
import SwiftUI
import ActivityKit
import SwiftData

@Observable
class ViewModel {
    typealias AlarmConfiguration = AlarmManager.AlarmConfiguration<TimerData>
    typealias AlarmsMap = [UUID: (Alarm, String)]
    typealias AlarmActivity = Activity<AlarmAttributes<TimerData>>
    
    @MainActor var alarmsMap = AlarmsMap()
    @ObservationIgnored private let alarmManager = AlarmManager.shared
    @ObservationIgnored var modelContext: ModelContext?
    
    @MainActor var hasScheduledAlarms: Bool {
        !alarmsMap.isEmpty
    }
    
    @MainActor var activity: Activity<AlarmAttributes<TimerData>>?
    
    // MARK: NOT USED
    // This checks if LA exists for alarm id
    func isLiveActivityActive(for id: UUID) -> Bool {
        let idString = id.uuidString
        return Activity<AlarmAttributes<TimerData>>.activities.contains(where: {
            $0.id == idString
            && ($0.activityState == .active || $0.activityState == .stale)
        })
    }
    
    // MARK: NOT USED
    // This only assigns to the activity list but does not recreate a dismissed LA
    func restoreLiveActivity(for id: UUID) {
        if let existingActivity = Activity<AlarmAttributes<TimerData>>.activities.first(where: {
            $0.id == id.uuidString
        }) {
            self.activity = existingActivity
        }
    }
    
    init() {
        observeAlarms()
    }
    
    // Fetch alarm model for the uuid
    func alarmModel(for id: UUID) -> AlarmModel? {
        guard let context = modelContext else { return nil }
        return try? context.fetch(FetchDescriptor<AlarmModel>(predicate: #Predicate { $0.id == id })).first
    }
    
    func createdAt(for id: UUID) -> Date? {
        alarmModel(for: id)?.createdAt
    }
    
    func duration(for id: UUID) -> TimeInterval? {
        alarmModel(for: id)?.duration
    }
    
    func adjustedRemaining(for id: UUID) -> TimeInterval? {
        alarmModel(for: id)?.adjustedRemaining
    }
    
    func scheduleAlarm(with duration: TimeInterval, label: String) {
        let attributes = AlarmAttributes(presentation: alarmPresentation(with: duration, label: LocalizedStringResource(stringLiteral: label)), metadata: TimerData(duration: duration, label: label), tintColor: Color.accentColor)
        let id = UUID()
        let sound = AlertConfiguration.AlertSound.default // Or use .name("filename") but it doesn't work
        let alarmConfiguration = AlarmConfiguration(
            countdownDuration: .init(preAlert: duration, postAlert: nil),
            attributes: attributes,
            sound: sound
        )
        
        scheduleAlarm(id: id, label: label, alarmConfiguration: alarmConfiguration, duration: duration)
    }
    
    func scheduleAlarm(id: UUID, label: String, alarmConfiguration: AlarmConfiguration, duration: TimeInterval) {
        Task {
            do {
                guard await requestAuthorization() else {
                    print("Not authorized to schedule alarm")
                    return
                }
                let alarm = try await alarmManager.schedule(id: id, configuration: alarmConfiguration)
                await MainActor.run {
                    alarmsMap[id] = (alarm, label)
                    
                    if let context = modelContext {
                        let newAlarm = AlarmModel(
                            id: id,
                            createdAt: Date(),
                            duration: duration,
                            adjustedRemaining: nil
                        )
                        context.insert(newAlarm)
                        print("Added alarm with id: \(id)")
                        try? context.save()
                    }
                }
            } catch {
                print("Error occured while scheduling alarm: \(error)")
            }
        }
    }
    
    func unscheduleAlarm(with alarmID: UUID) {
        try? alarmManager.cancel(id: alarmID)
        Task { @MainActor in
            removeAlarmModel(for: alarmID)
            alarmsMap[alarmID] = nil
        }
    }
    
    func pause(with alarmID: UUID) {
        guard let (alarm, _) = alarmsMap[alarmID] else { return }
        
        guard case .countdown = alarm.state else { return }
        
        if let context = modelContext,
           let model = try? context.fetch(
            FetchDescriptor<AlarmModel>(predicate: #Predicate { $0.id == alarmID })
           ).first,
           let createdAt = model.createdAt,
           let duration = model.duration {
            let elapsed = Date().timeIntervalSince(createdAt)
            let remaining = max(duration - elapsed, 0)
            model.adjustedRemaining = remaining
            try? context.save()
            print("Alarm paused, model saved with remaining: \(remaining)")
        }
        
        Task {
            do {
                try alarmManager.pause(id: alarmID)
                print("Paused alarm with ID: \(alarmID)")
            } catch {
                print("Failed to pause alarm with ID: \(alarmID)")
            }
        }
    }
    
    func resume(with alarmID: UUID) {
        guard let (alarm, _) = alarmsMap[alarmID] else { return }
        
        guard case .paused = alarm.state else { return }
        
        if let context = modelContext,
           let model = try? context.fetch(
            FetchDescriptor<AlarmModel>(predicate: #Predicate { $0.id == alarmID })
           ).first {
            if let remaining = model.adjustedRemaining,
               let duration = model.duration {
                let elapsed = max(duration - remaining, 0)
                let newCreatedAt = Date().addingTimeInterval(-elapsed)
                model.createdAt = newCreatedAt
                model.adjustedRemaining = nil
            }
            
            try? context.save()
            
            print("Alarm resume, model updated with createdAt: \(String(describing: model.createdAt)), duration: \(String(describing: model.duration))")
        }
        
        Task {
            do {
                try alarmManager.resume(id: alarmID)
                print("Resume alarm with ID: \(alarmID)")
            } catch {
                print("Failed to resume alarm with ID: \(alarmID)")
            }
        }
    }
    
    private func alarmPresentation(with duration: TimeInterval, label: LocalizedStringResource?) -> AlarmPresentation {
        let alertContent = AlarmPresentation.Alert(title: label ?? "Alarm", stopButton: .stopButton)
        
        guard duration > 0 else {
            return AlarmPresentation(alert: alertContent)
        }
        
        let countdownContent = AlarmPresentation.Countdown(title: "Alarm", pauseButton: .pauseButton)
        
        let pausedContent = AlarmPresentation.Paused(title: "Paused", resumeButton: .resumeButton)
        
        return AlarmPresentation(alert: alertContent, countdown: countdownContent, paused: pausedContent)
    }
    
    private func observeAlarms() {
        Task {
            for await incomingAlarms in alarmManager.alarmUpdates {
                updateAlarmState(with: incomingAlarms)
            }
        }
    }
    
    private func updateAlarmState(with remoteAlarms: [Alarm]) {
        Task { @MainActor in
            // Update existing alarm states
            remoteAlarms.forEach { updated in
                alarmsMap[updated.id, default: (updated, "Alarm (Old Session)")].0 = updated
            }
            
            let knownAlarmIDs = Set(alarmsMap.keys)
            let incomingAlarmIDs = Set(remoteAlarms.map(\.id))
            
            // Remove completed alarms
            let removedAlarmsIDs = Set(knownAlarmIDs.subtracting(incomingAlarmIDs))
            removedAlarmsIDs.forEach { id in
                alarmsMap[id] = nil
                removeAlarmModel(for: id)
            }
        }
    }
    
    private func removeAlarmModel(for id: UUID) {
        guard let context = modelContext,
              let model = try? context.fetch(
                FetchDescriptor<AlarmModel>(predicate: #Predicate { $0.id == id })
              ).first
        else {
            return
        }
        print("Removing alarm with id: \(id)")
        context.delete(model)
        try? context.save()
    }
    
    private func requestAuthorization() async -> Bool {
        switch alarmManager.authorizationState {
        case .notDetermined:
            do {
                let state = try await alarmManager.requestAuthorization()
                return state == .authorized
            } catch {
                print("Error occured while requesting authorization: \(error)")
                return false
            }
        case .authorized: return true
        case .denied: return false
        @unknown default: return false
        }
    }
}

extension Alarm {
    var alertingTime: Date? {
        guard let schedule else { return nil }
        
        switch schedule {
        case .fixed(let date):
            return date
        case .relative(let relative):
            var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
            components.hour = relative.time.hour
            components.minute = relative.time.minute
            return Calendar.current.date(from: components)
        @unknown default: return nil
        }
    }
}

extension TimeInterval {
    func customFormatted() -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: self) ?? self.formatted()
    }
}

extension AlarmButton {
    static var openAppButton: Self {
        AlarmButton(text: "Open", textColor: .white, systemImageName: "timer")
    }
    
    static var pauseButton: Self {
        AlarmButton(text: "Pause", textColor: .white, systemImageName: "pause.fill")
    }
    
    static var resumeButton: Self {
        AlarmButton(text: "Resume", textColor: .white, systemImageName: "play.fill")
    }
    
    static var stopButton: Self {
        AlarmButton(text: "Done", textColor: .white, systemImageName: "stop.fill")
    }
}
