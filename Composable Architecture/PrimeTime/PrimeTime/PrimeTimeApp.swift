//
//  PrimeTimeApp.swift
//  PrimeTime
//
//  Created by Guillermo Muntaner on 01.03.23.
//

import SwiftUI

@main
struct PrimeTimeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                store: Store(
                    initialValue: AppState(),
                    reducer: appReducer
                )
            )
        }
    }
}
