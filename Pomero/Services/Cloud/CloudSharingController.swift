import CloudKit
import SwiftUI
import UIKit

/// SwiftUI wrapper around `UICloudSharingController` — the system sheet that lets the
/// user send a connection invite (Messages / Mail / AirDrop / copy link) and manage
/// participants. iOS-only: there is no equivalent on watchOS, which is why pairing
/// lives in the iPhone companion.
struct CloudSharingController: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            // The share was already saved before presenting; log any late failure.
            print("CloudSharingController failed: \(error.localizedDescription)")
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            "Pomero connection"
        }
    }
}
