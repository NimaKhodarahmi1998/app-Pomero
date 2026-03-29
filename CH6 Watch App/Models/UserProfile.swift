//
//  UserProfile.swift
//  CH6 Watch App
//
//  Created by Aleksandra Stupiec on 30/03/26.
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: String
    var displayName: String
    var emoji: String
    var spaceColor: SpaceColor
    var createdAt: Date

    // Auth — will be populated when Firebase is integrated
    var authProvider: String?
    var email: String?

    // Pairing
    var partnerID: String?
    var pairCode: String?
    var isPaired: Bool

    init(
        id: String = UUID().uuidString,
        displayName: String,
        emoji: String = "😊",
        spaceColor: SpaceColor = .blue
    ) {
        self.id = id
        self.displayName = displayName
        self.emoji = emoji
        self.spaceColor = spaceColor
        self.createdAt = .now
        self.isPaired = false
    }

    /// Generates a short code the partner can use to connect
    func generatePairCode() -> String {
        let code = String(UUID().uuidString.prefix(6)).uppercased()
        self.pairCode = code
        return code
    }
}
