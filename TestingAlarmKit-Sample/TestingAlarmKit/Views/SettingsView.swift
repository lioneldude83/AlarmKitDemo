//
//  SettingsView.swift
//  TestingAlarmKit
//
//  Created by Lionel Ng on 19/6/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(ViewModel.self) var viewModel
    @Environment(\.dismiss) var dismiss
    
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int
    @Binding var label: String
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.red)
                }
                
                Spacer()
                Button(action: {
                    let duration = TimeInterval(hours * 3600 + minutes * 60 + seconds)
                    // Schedule alarm with duration
                    viewModel.scheduleAlarm(with: duration, label: label)
                    dismiss()
                }) {
                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.green)
                }
                .disabled(hours == 0 && minutes == 0 && seconds == 0)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            
            Text("Set Timer Duration")
                .font(.title3)
                .padding(.bottom, 12)
            PickerView(hours: $hours, minutes: $minutes, seconds: $seconds)
            
            HStack {
                Text("Label:")
                Spacer()
                TextField("Enter label", text: $label)
                    .multilineTextAlignment(.trailing)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray.opacity(0.65))
            )
            .padding(.horizontal, 24)
        }
        .padding()
        .presentationDetents([.height(340)])
    }
}

#Preview {
    let viewModel = ViewModel()
    
    SettingsView(
        hours: .constant(0),
        minutes: .constant(1),
        seconds: .constant(0),
        label: .constant("Test")
    )
    .environment(viewModel)
}
