//
//  StandupsApp.swift
//  Standups
//
//  Created by Guillermo Muntaner on 13.02.23.
//

import SwiftUI

@main
struct StandupsApp: App {
    var body: some Scene {
        WindowGroup {
            StandupsList(model: StandupsListModel())
        }
    }
}
