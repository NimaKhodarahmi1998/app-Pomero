import Foundation

// MARK: - Message Actions

enum WatchMessageAction: String {
    // Watch -> Phone
    case contactCreated
    case contactUpdated
    case contactDeleted
    case nudgeSent
    case moodSet
    case songSuggested
    case customChallengeCreated
    case customChallengeToggled
    case challengeUpdated
    case achievementUnlocked
    case userProfileUpdated

    // Phone -> Watch
    case authStateChanged
    case fullSync
}

// MARK: - Message Keys

enum WatchMessageKey {
    static let action = "action"
    static let payload = "payload"
    static let timestamp = "timestamp"

    // Contact fields
    static let contactName = "contactName"
    static let relationship = "relationship"
    static let emoji = "emoji"
    static let spaceColor = "spaceColor"
    static let nickname = "nickname"
    static let currentMood = "currentMood"
    static let streakCount = "streakCount"
    static let lastInteractionDate = "lastInteractionDate"
    static let totalNudgesSent = "totalNudgesSent"
    static let totalMoodsSet = "totalMoodsSet"
    static let uniqueMoodsUsed = "uniqueMoodsUsed"
    static let lastNudgeDate = "lastNudgeDate"

    // Nudge fields
    static let nudgeType = "nudgeType"
    static let isSent = "isSent"

    // Mood fields
    static let moodType = "moodType"
    static let note = "note"

    // Song fields
    static let songTitle = "songTitle"
    static let artistName = "artistName"
    static let albumTitle = "albumTitle"
    static let appleMusicURL = "appleMusicURL"

    // Challenge fields
    static let challengeType = "challengeType"
    static let progress = "progress"
    static let isCompleted = "isCompleted"
    static let startDate = "startDate"

    // Custom challenge fields
    static let title = "title"
    static let completedAt = "completedAt"
    static let createdAt = "createdAt"

    // Achievement fields
    static let achievementType = "achievementType"
    static let unlockedAt = "unlockedAt"

    // Auth fields
    static let isSignedIn = "isSignedIn"
    static let uid = "uid"
    static let email = "email"

    // Profile fields
    static let displayName = "displayName"
    static let partnerID = "partnerID"
    static let pairCode = "pairCode"
    static let isPaired = "isPaired"

    // Challenge list for contact creation
    static let challenges = "challenges"
}

// MARK: - Message Builder

enum WatchMessage {

    static func build(action: WatchMessageAction, payload: [String: Any]) -> [String: Any] {
        [
            WatchMessageKey.action: action.rawValue,
            WatchMessageKey.payload: payload,
            WatchMessageKey.timestamp: Date().timeIntervalSince1970
        ]
    }

    static func parse(_ message: [String: Any]) -> (action: WatchMessageAction, payload: [String: Any])? {
        guard let actionRaw = message[WatchMessageKey.action] as? String,
              let action = WatchMessageAction(rawValue: actionRaw),
              let payload = message[WatchMessageKey.payload] as? [String: Any] else {
            return nil
        }
        return (action, payload)
    }

    // MARK: - Watch -> Phone Builders

    static func contactCreated(
        name: String,
        relationship: String,
        emoji: String,
        spaceColor: String,
        challengeTypes: [String]
    ) -> [String: Any] {
        build(action: .contactCreated, payload: [
            WatchMessageKey.contactName: name,
            WatchMessageKey.relationship: relationship,
            WatchMessageKey.emoji: emoji,
            WatchMessageKey.spaceColor: spaceColor,
            WatchMessageKey.challenges: challengeTypes
        ])
    }

    static func contactUpdated(
        name: String,
        fields: [String: Any]
    ) -> [String: Any] {
        var payload = fields
        payload[WatchMessageKey.contactName] = name
        return build(action: .contactUpdated, payload: payload)
    }

    static func contactDeleted(name: String) -> [String: Any] {
        build(action: .contactDeleted, payload: [
            WatchMessageKey.contactName: name
        ])
    }

    static func nudgeSent(
        type: String,
        contactName: String,
        isSent: Bool,
        contactStats: [String: Any]
    ) -> [String: Any] {
        var payload = contactStats
        payload[WatchMessageKey.nudgeType] = type
        payload[WatchMessageKey.contactName] = contactName
        payload[WatchMessageKey.isSent] = isSent
        payload[WatchMessageKey.timestamp] = Date().timeIntervalSince1970
        return build(action: .nudgeSent, payload: payload)
    }

    static func moodSet(
        type: String,
        contactName: String,
        note: String?,
        contactStats: [String: Any]
    ) -> [String: Any] {
        var payload = contactStats
        payload[WatchMessageKey.moodType] = type
        payload[WatchMessageKey.contactName] = contactName
        payload[WatchMessageKey.timestamp] = Date().timeIntervalSince1970
        if let note { payload[WatchMessageKey.note] = note }
        return build(action: .moodSet, payload: payload)
    }

    static func songSuggested(
        songTitle: String,
        artistName: String,
        albumTitle: String,
        appleMusicURL: String?,
        contactName: String
    ) -> [String: Any] {
        var payload: [String: Any] = [
            WatchMessageKey.songTitle: songTitle,
            WatchMessageKey.artistName: artistName,
            WatchMessageKey.albumTitle: albumTitle,
            WatchMessageKey.contactName: contactName,
            WatchMessageKey.timestamp: Date().timeIntervalSince1970
        ]
        if let appleMusicURL { payload[WatchMessageKey.appleMusicURL] = appleMusicURL }
        return build(action: .songSuggested, payload: payload)
    }

    static func customChallengeCreated(
        title: String,
        contactName: String
    ) -> [String: Any] {
        build(action: .customChallengeCreated, payload: [
            WatchMessageKey.title: title,
            WatchMessageKey.contactName: contactName,
            WatchMessageKey.createdAt: Date().timeIntervalSince1970
        ])
    }

    static func customChallengeToggled(
        title: String,
        contactName: String,
        isCompleted: Bool,
        completedAt: Double?
    ) -> [String: Any] {
        var payload: [String: Any] = [
            WatchMessageKey.title: title,
            WatchMessageKey.contactName: contactName,
            WatchMessageKey.isCompleted: isCompleted
        ]
        if let completedAt { payload[WatchMessageKey.completedAt] = completedAt }
        return build(action: .customChallengeToggled, payload: payload)
    }

    static func challengeUpdated(
        type: String,
        contactName: String,
        progress: Int,
        isCompleted: Bool,
        startDate: Double
    ) -> [String: Any] {
        build(action: .challengeUpdated, payload: [
            WatchMessageKey.challengeType: type,
            WatchMessageKey.contactName: contactName,
            WatchMessageKey.progress: progress,
            WatchMessageKey.isCompleted: isCompleted,
            WatchMessageKey.startDate: startDate
        ])
    }

    static func achievementUnlocked(
        type: String,
        contactName: String,
        unlockedAt: Double
    ) -> [String: Any] {
        build(action: .achievementUnlocked, payload: [
            WatchMessageKey.achievementType: type,
            WatchMessageKey.contactName: contactName,
            WatchMessageKey.unlockedAt: unlockedAt
        ])
    }

    // MARK: - Helper: Contact Stats Snapshot

    static func contactStatsPayload(
        streakCount: Int,
        totalNudgesSent: Int,
        totalMoodsSet: Int,
        uniqueMoodsUsed: [String],
        currentMood: String?,
        lastInteractionDate: Double?,
        lastNudgeDate: Double?
    ) -> [String: Any] {
        var stats: [String: Any] = [
            WatchMessageKey.streakCount: streakCount,
            WatchMessageKey.totalNudgesSent: totalNudgesSent,
            WatchMessageKey.totalMoodsSet: totalMoodsSet,
            WatchMessageKey.uniqueMoodsUsed: uniqueMoodsUsed
        ]
        if let currentMood { stats[WatchMessageKey.currentMood] = currentMood }
        if let lastInteractionDate { stats[WatchMessageKey.lastInteractionDate] = lastInteractionDate }
        if let lastNudgeDate { stats[WatchMessageKey.lastNudgeDate] = lastNudgeDate }
        return stats
    }

    // MARK: - Phone -> Watch Builders

    static func authStateChanged(
        isSignedIn: Bool,
        uid: String?,
        email: String?
    ) -> [String: Any] {
        var payload: [String: Any] = [
            WatchMessageKey.isSignedIn: isSignedIn
        ]
        if let uid { payload[WatchMessageKey.uid] = uid }
        if let email { payload[WatchMessageKey.email] = email }
        return payload // Used directly as applicationContext, not wrapped
    }

    static func fullSync(contacts: [[String: Any]]) -> [String: Any] {
        build(action: .fullSync, payload: [
            WatchMessageKey.contacts: contacts
        ])
    }
}

// MARK: - Additional Keys

extension WatchMessageKey {
    static let contacts = "contacts"
}
