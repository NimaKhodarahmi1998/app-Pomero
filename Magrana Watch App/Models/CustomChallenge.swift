import Foundation
import SwiftData

@Model
final class CustomChallenge {
    var title: String
    var contactName: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?

    init(title: String, contactName: String) {
        self.title = title
        self.contactName = contactName
        self.isCompleted = false
        self.createdAt = .now
    }
}
