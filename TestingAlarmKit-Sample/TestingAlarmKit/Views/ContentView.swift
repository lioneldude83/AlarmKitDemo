//
//  ContentView.swift
//  TestingAlarmKit
//
//  Created by Lionel Ng on 18/6/25.
//

import SwiftUI
import AlarmKit
import ActivityKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ViewModel.self) var viewModel
    @Environment(\.scenePhase) var scenePhase
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    @State private var label = ""
    
    @State private var showSettingsSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if !viewModel.hasScheduledAlarms {
                    SettingsView(hours: $hours, minutes: $minutes, seconds: $seconds, label: $label)
                } else {
                    content
                    Spacer()
                    
                }
            }
            .toolbar {
                ToolbarItem {
                    addAlarmButton()
                        .foregroundStyle(.green)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.modelContext = modelContext
            print("Model context injected into view model")
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Blank for now
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView(hours: $hours, minutes: $minutes, seconds: $seconds, label: $label)
        }
        
    }
    
    @ViewBuilder
    var content: some View {
        if viewModel.hasScheduledAlarms {
            alarmList(alarms: Array(viewModel.alarmsMap.values))
        }
    }
    
    @ViewBuilder
    private func addAlarmButton() -> some View {
        Button(action: {
            showSettingsSheet = true
        }) {
            Image(systemName: "plus")
        }
        .buttonStyle(.glass)
    }
    
    func alarmList(alarms: [ViewModel.AlarmsMap.Value]) -> some View {
        List {
            ForEach(alarms, id: \.0.id) { (alarm, label) in
                AlarmCell(alarm: alarm, label: label)
            }
            .onDelete { indexSet in
                indexSet.forEach { idx in
                    viewModel.unscheduleAlarm(with: alarms[idx].0.id)
                }
            }
        }
    }
}

struct AlarmCell: View {
    var alarm: Alarm
    var label: String
    @Environment(ViewModel.self) var viewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    if label.isEmpty {
                        Text("Alarm")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    } else {
                        Text(label)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    
                    switch alarm.state {
                    case .scheduled:
                        Image(systemName: "clock")
                            .foregroundStyle(.gray)
                    case .countdown:
                        if let start = viewModel.createdAt(for: alarm.id),
                           let duration = viewModel.duration(for: alarm.id) {
                            let end = start + duration
                            Text(timerInterval: start...end, countsDown: true)
                                .font(.title)
                                .fontWeight(.medium)
                                .foregroundStyle(.cyan)
                        }
                    case .paused:
                        let remaining = viewModel.adjustedRemaining(for: alarm.id) ?? 0
                        Text(formatTime(remaining))
                            .font(.title)
                            .foregroundStyle(.yellow)
                    case .alerting:
                        Text("Done")
                            .font(.title)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                    @unknown default:
                        EmptyView()
                    }
                }
                Spacer()
                
                alarmState()
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func alarmState() -> some View {
        switch alarm.state {
        case .scheduled:
            EmptyView()
        case .countdown:
            Button(action: {
                viewModel.pause(with: alarm.id)
            }) {
                Image(systemName: "pause.circle.fill")
                    .resizable()
                    .frame(width: 48, height: 48)
                    .foregroundColor(.orange)
            }
        case .paused:
            Button(action: {
                viewModel.resume(with: alarm.id)
            }) {
                Image(systemName: "play.circle.fill")
                    .resizable()
                    .frame(width: 48, height: 48)
                    .foregroundColor(.green)
            }
        case .alerting:
            Button(action: {
                viewModel.unscheduleAlarm(with: alarm.id)
            }) {
                Image(systemName: "stop.circle.fill")
                    .resizable()
                    .frame(width: 48, height: 48)
                    .foregroundColor(.cyan)
            }
        @unknown default: EmptyView()
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    let viewModel = ViewModel()
    ContentView()
        .environment(viewModel)
}
