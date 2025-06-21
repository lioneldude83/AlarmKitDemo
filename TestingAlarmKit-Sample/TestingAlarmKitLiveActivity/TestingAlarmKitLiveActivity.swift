//
//  TestingAlarmKitLiveActivity.swift
//  TestingAlarmKitLiveActivityExtension
//
//  Created by Lionel Ng on 19/6/25.
//

import ActivityKit
import WidgetKit
import SwiftUI
import AlarmKit
import AppIntents

struct TestingAlarmKitLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<TimerData>.self) { context in
            lockScreenView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Color.cyan.opacity(0.85))
                .activitySystemActionForegroundColor(Color.white)
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    AlarmProgressView(mode: context.state.mode, tint: context.attributes.tintColor)
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    alarmTitle(attributes: context.attributes, state: context.state)
                        .padding(.trailing, 6)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    bottomView(attributes: context.attributes, state: context.state)
                        .padding(.horizontal, 2)
                }
            } compactLeading: {
                countdown(state: context.state, maxWidth: 44)
                    .foregroundStyle(context.attributes.tintColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            } compactTrailing: {
                AlarmProgressView(mode: context.state.mode, tint: context.attributes.tintColor)
            } minimal: {
                AlarmProgressView(mode: context.state.mode, tint: context.attributes.tintColor)
            }
            .keylineTint(Color.cyan)
        }
    }
    
    func lockScreenView(attributes: AlarmAttributes<TimerData>, state: AlarmPresentationState) -> some View {
        VStack {
            HStack(alignment: .top) {
                alarmTitle(attributes: attributes, state: state)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            bottomView(attributes: attributes, state: state)
        }
        .padding(.all, 12)
    }
    
    func bottomView(attributes: AlarmAttributes<TimerData>, state: AlarmPresentationState) -> some View {
        HStack {
            countdown(state: state, maxWidth: 150)
                .font(.system(size: 36, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Spacer()
            AlarmControls(presentation: attributes.presentation, state: state)
                .minimumScaleFactor(0.65)
        }
    }
    
    func countdown(state: AlarmPresentationState, maxWidth: CGFloat) -> some View {
        Group {
            switch state.mode {
            case .countdown(let countdown):
                Text(timerInterval: Date.now...countdown.fireDate, countsDown: true)
                    .frame(maxWidth: maxWidth)
            case .paused(let state):
                let remaining = Duration.seconds(state.totalCountdownDuration - state.previouslyElapsedDuration)
                let pattern: Duration.TimeFormatStyle.Pattern = remaining > .seconds(60 * 60) ? .hourMinuteSecond : .minuteSecond
                Text(remaining.formatted(.time(pattern: pattern)))
                    .frame(maxWidth: maxWidth)
            default:
                EmptyView()
            }
        }
    }
    
    @ViewBuilder func alarmTitle(attributes: AlarmAttributes<TimerData>, state: AlarmPresentationState) -> some View {
        let title: LocalizedStringResource? = switch state.mode {
        case .countdown:
            attributes.presentation.countdown?.title
        case .paused:
            attributes.presentation.paused?.title
        default:
            nil
        }
        
        if attributes.metadata?.label != nil {
            Text("\(title ?? "") \(attributes.metadata?.label ?? "")")
                .font(.title3)
                .fontWeight(.medium)
        } else {
            Text(title ?? "")
                .font(.title3)
                .fontWeight(.medium)
        }
    }
}

struct AlarmProgressView: View {
    var mode: AlarmPresentationState.Mode
    var tint: Color
    
    var body: some View {
        Group {
            switch mode {
            case .countdown(let countdown):
                let end = countdown.fireDate
                let total = countdown.totalCountdownDuration
                let start = end.addingTimeInterval(-total)
                
                ProgressView(
                    timerInterval: start...end,
                    countsDown: true,
                    label: { EmptyView() },
                    currentValueLabel: {
                        Image(systemName: "pause.fill")
                            .scaleEffect(0.8)
                    }
                )
            case .paused(let pausedState):
                let remaining = pausedState.totalCountdownDuration - pausedState.previouslyElapsedDuration
                
                ProgressView(
                    value: remaining,
                    total: pausedState.totalCountdownDuration,
                    label: { EmptyView() },
                    currentValueLabel: {
                        Image(systemName: "play.fill")
                            .scaleEffect(0.8)
                    }
                )
            default:
                EmptyView()
            }
        }
        .progressViewStyle(.circular)
        .foregroundColor(tint)
        .tint(tint)
    }
}

struct AlarmControls: View {
    var presentation: AlarmPresentation
    var state: AlarmPresentationState
    
    var body: some View {
        HStack(spacing: 4) {
            switch state.mode {
            case .countdown:
                ButtonView(config: presentation.countdown?.pauseButton, intent: PauseIntent(alarmID: state.alarmID.uuidString), tint: .orange)
            case .paused:
                ButtonView(config: presentation.paused?.resumeButton, intent: ResumeIntent(alarmID: state.alarmID.uuidString), tint: .green)
            default:
                EmptyView()
            }
            
            ButtonView(config: presentation.alert.stopButton, intent: StopIntent(alarmID: state.alarmID.uuidString), tint: .red)
        }
    }
}

struct ButtonView<I>: View where I: AppIntent {
    var config: AlarmButton
    var intent: I
    var tint: Color
    
    init?(config: AlarmButton?, intent: I, tint: Color) {
        guard let config else { return nil }
        self.config = config
        self.intent = intent
        self.tint = tint
    }
    
    var body: some View {
        Button(intent: intent) {
            Label(config.text, systemImage: config.systemImageName)
                .lineLimit(1)
        }
        .tint(tint)
        .buttonStyle(.borderedProminent)
        .frame(width: 96, height: 30)
    }
}
