//
//  PickerView.swift
//  TestingAlarmKit
//
//  Created by Lionel Ng on 19/6/25.
//

import SwiftUI

struct PickerView: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int
    
    var body: some View {
        HStack(spacing: 0) {
            Picker("", selection: $hours) {
                ForEach(0..<24, id: \.self) { Text("\($0) h") }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(maxWidth: .infinity)
            
            Picker("", selection: $minutes) {
                ForEach(0..<60, id: \.self) { Text("\($0) m") }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(maxWidth: .infinity)
            
            Picker("", selection: $seconds) {
                ForEach(0..<60, id: \.self) { Text("\($0) s") }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(maxWidth: .infinity)
        }
        .frame(height: 150)
        .labelsHidden()
        .clipped()
    }
}

struct PickerViewPreviewWrapper: View {
    @State static var hours = 0
    @State static var minutes = 2
    @State static var seconds = 30
    
    var body: some View {
        PickerView(
            hours: PickerViewPreviewWrapper.$hours,
            minutes: PickerViewPreviewWrapper.$minutes,
            seconds: PickerViewPreviewWrapper.$seconds
        )
    }
}

#Preview {
    PickerViewPreviewWrapper()
}
