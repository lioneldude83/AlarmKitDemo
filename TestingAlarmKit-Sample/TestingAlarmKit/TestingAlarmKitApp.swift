//
//  TestingAlarmKitApp.swift
//  TestingAlarmKit
//
//  Created by Lionel Ng on 18/6/25.
//

import SwiftUI
import SwiftData

@main
struct TestingAlarmKitApp: App {
    let container: ModelContainer
    
    init() {
        let schema = Schema([AlarmModel.self])
        let modelConfiguration = ModelConfiguration(schema: schema, allowsSave: true)
        
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("Model Container created successfully.")
        } catch {
            fatalError("Could not create Model Container: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        let viewModel = ViewModel()
        
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
        .modelContainer(for: AlarmModel.self)
    }
}
