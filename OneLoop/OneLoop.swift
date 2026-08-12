//
//  OneLoop.swift
//  OneLoop
//
//  Created by David Carranco on 2026-08-01.
//

import SwiftUI

@main
struct OneLoopApp: App {
    @State private var medicationStore = MedicationStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(medicationStore)
        }
    }
}
