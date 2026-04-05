//
//  CH6App.swift
//  CH6
//
//  Created by Nima Khodarahmi on 27/03/26.
//

import SwiftUI
import FirebaseCore

@main
struct CH6App: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
