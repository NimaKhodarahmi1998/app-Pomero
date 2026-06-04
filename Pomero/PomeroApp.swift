//
//  PomeroApp.swift
//  Pomero
//
//  Created by Nima Khodarahmi on 27/03/26.
//

import CloudKit
import SwiftUI

@main
struct PomeroApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// Handles the system callback fired when the user taps a Pomero connection invite link.
/// CloudKit hands us the share metadata; we accept it so the shared zone becomes visible
/// to this account.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        Task {
            do {
                try await CloudConnectionService.shared.acceptShare(metadata: cloudKitShareMetadata)
                await CloudConnectionService.shared.refreshAccountStatus()
            } catch {
                print("Failed to accept share: \(error.localizedDescription)")
            }
        }
    }
}
