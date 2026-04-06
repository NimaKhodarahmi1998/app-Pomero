import Foundation
import WatchConnectivity
import FirebaseAuth

@MainActor
@Observable
final class PhoneConnectivityService: NSObject {
    static let shared = PhoneConnectivityService()

    var isWatchReachable: Bool { session.isReachable }

    private let session = WCSession.default
    private var delegate: SessionDelegate?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let del = SessionDelegate { [weak self] userInfo in
            self?.handleWatchMessage(userInfo)
        }
        self.delegate = del
        session.delegate = del
        session.activate()
    }

    // MARK: - Send Auth State to Watch

    func pushAuthState() {
        guard WCSession.isSupported() else { return }
        let user = AuthService.shared.currentUser
        let context = WatchMessage.authStateChanged(
            isSignedIn: user != nil,
            uid: user?.uid,
            email: user?.email
        )
        try? session.updateApplicationContext(context)

        // Trigger full sync when user signs in
        if user != nil {
            Task { await performFullSync() }
        }
    }

    // MARK: - Full Sync (Phone -> Watch)

    func performFullSync() async {
        do {
            let contacts = try await FirestoreService.fetchAllContacts()
            let message = WatchMessage.fullSync(contacts: contacts)
            session.transferUserInfo(message)
            print("[PhoneConnectivity] Full sync sent with \(contacts.count) contacts")
        } catch {
            print("[PhoneConnectivity] Full sync failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle Messages from Watch

    private func handleWatchMessage(_ message: [String: Any]) {
        guard let (action, payload) = WatchMessage.parse(message) else {
            print("[PhoneConnectivity] Failed to parse message")
            return
        }

        Task {
            do {
                switch action {
                case .contactCreated:
                    try await handleContactCreated(payload)
                case .contactUpdated:
                    try await handleContactUpdated(payload)
                case .contactDeleted:
                    try await handleContactDeleted(payload)
                case .nudgeSent:
                    try await handleNudgeSent(payload)
                case .moodSet:
                    try await handleMoodSet(payload)
                case .songSuggested:
                    try await handleSongSuggested(payload)
                case .customChallengeCreated:
                    try await handleCustomChallengeCreated(payload)
                case .customChallengeToggled:
                    try await handleCustomChallengeToggled(payload)
                case .challengeUpdated:
                    try await handleChallengeUpdated(payload)
                case .achievementUnlocked:
                    try await handleAchievementUnlocked(payload)
                case .userProfileUpdated:
                    try await handleUserProfileUpdated(payload)
                case .authStateChanged, .fullSync:
                    break // Phone doesn't handle these
                }
            } catch {
                print("[PhoneConnectivity] Firestore write failed for \(action.rawValue): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Handlers

    private func handleContactCreated(_ payload: [String: Any]) async throws {
        guard let name = payload[WatchMessageKey.contactName] as? String,
              let relationship = payload[WatchMessageKey.relationship] as? String,
              let emoji = payload[WatchMessageKey.emoji] as? String,
              let spaceColor = payload[WatchMessageKey.spaceColor] as? String else { return }

        let challengeTypes = payload[WatchMessageKey.challenges] as? [String] ?? []

        try await FirestoreService.createContact(
            name: name,
            relationship: relationship,
            emoji: emoji,
            spaceColor: spaceColor,
            challengeTypes: challengeTypes
        )
    }

    private func handleContactUpdated(_ payload: [String: Any]) async throws {
        guard let name = payload[WatchMessageKey.contactName] as? String else { return }
        var fields = payload
        fields.removeValue(forKey: WatchMessageKey.contactName)
        try await FirestoreService.updateContact(name: name, fields: fields)
    }

    private func handleContactDeleted(_ payload: [String: Any]) async throws {
        guard let name = payload[WatchMessageKey.contactName] as? String else { return }
        try await FirestoreService.deleteContact(name: name)
    }

    private func handleNudgeSent(_ payload: [String: Any]) async throws {
        guard let contactName = payload[WatchMessageKey.contactName] as? String,
              let nudgeType = payload[WatchMessageKey.nudgeType] as? String,
              let timestamp = payload[WatchMessageKey.timestamp] as? Double else { return }

        let isSent = payload[WatchMessageKey.isSent] as? Bool ?? true

        try await FirestoreService.addNudge(
            contactName: contactName,
            type: nudgeType,
            timestamp: timestamp,
            isSent: isSent
        )
        try await FirestoreService.updateContactStats(
            contactName: contactName,
            stats: extractContactStats(payload)
        )
    }

    private func handleMoodSet(_ payload: [String: Any]) async throws {
        guard let contactName = payload[WatchMessageKey.contactName] as? String,
              let moodType = payload[WatchMessageKey.moodType] as? String,
              let timestamp = payload[WatchMessageKey.timestamp] as? Double else { return }

        let note = payload[WatchMessageKey.note] as? String

        try await FirestoreService.addMood(
            contactName: contactName,
            type: moodType,
            timestamp: timestamp,
            note: note
        )
        try await FirestoreService.updateContactStats(
            contactName: contactName,
            stats: extractContactStats(payload)
        )
    }

    private func handleSongSuggested(_ payload: [String: Any]) async throws {
        guard let contactName = payload[WatchMessageKey.contactName] as? String,
              let songTitle = payload[WatchMessageKey.songTitle] as? String,
              let artistName = payload[WatchMessageKey.artistName] as? String,
              let albumTitle = payload[WatchMessageKey.albumTitle] as? String,
              let timestamp = payload[WatchMessageKey.timestamp] as? Double else { return }

        let appleMusicURL = payload[WatchMessageKey.appleMusicURL] as? String

        try await FirestoreService.addSong(
            contactName: contactName,
            songTitle: songTitle,
            artistName: artistName,
            albumTitle: albumTitle,
            appleMusicURL: appleMusicURL,
            timestamp: timestamp
        )
    }

    private func handleCustomChallengeCreated(_ payload: [String: Any]) async throws {
        guard let contactName = payload[WatchMessageKey.contactName] as? String,
              let title = payload[WatchMessageKey.title] as? String,
              let createdAt = payload[WatchMessageKey.createdAt] as? Double else { return }

        try await FirestoreService.createCustomChallenge(
            contactName: contactName,
            title: title,
            createdAt: createdAt
        )
    }

    private func handleCustomChallengeToggled(_ payload: [String: Any]) async throws {
        guard let contactName = payload[WatchMessageKey.contactName] as? String,
              let title = payload[WatchMessageKey.title] as? String,
              let isCompleted = payload[WatchMessageKey.isCompleted] as? Bool else { return }

        let completedAt = payload[WatchMessageKey.completedAt] as? Double

        try await FirestoreService.updateCustomChallenge(
            contactName: contactName,
            title: title,
            isCompleted: isCompleted,
            completedAt: completedAt
        )
    }

    private func handleChallengeUpdated(_ payload: [String: Any]) async throws {
        guard let contactName = payload[WatchMessageKey.contactName] as? String,
              let type = payload[WatchMessageKey.challengeType] as? String,
              let progress = payload[WatchMessageKey.progress] as? Int,
              let isCompleted = payload[WatchMessageKey.isCompleted] as? Bool,
              let startDate = payload[WatchMessageKey.startDate] as? Double else { return }

        try await FirestoreService.updateChallenge(
            contactName: contactName,
            type: type,
            progress: progress,
            isCompleted: isCompleted,
            startDate: startDate
        )
    }

    private func handleAchievementUnlocked(_ payload: [String: Any]) async throws {
        guard let contactName = payload[WatchMessageKey.contactName] as? String,
              let type = payload[WatchMessageKey.achievementType] as? String,
              let unlockedAt = payload[WatchMessageKey.unlockedAt] as? Double else { return }

        try await FirestoreService.updateAchievement(
            contactName: contactName,
            type: type,
            isUnlocked: true,
            unlockedAt: unlockedAt
        )
    }

    private func handleUserProfileUpdated(_ payload: [String: Any]) async throws {
        try await FirestoreService.setProfile(payload)
    }

    // MARK: - Helpers

    private func extractContactStats(_ payload: [String: Any]) -> [String: Any] {
        var stats: [String: Any] = [:]
        if let v = payload[WatchMessageKey.streakCount] as? Int { stats["streakCount"] = v }
        if let v = payload[WatchMessageKey.totalNudgesSent] as? Int { stats["totalNudgesSent"] = v }
        if let v = payload[WatchMessageKey.totalMoodsSet] as? Int { stats["totalMoodsSet"] = v }
        if let v = payload[WatchMessageKey.uniqueMoodsUsed] as? [String] { stats["uniqueMoodsUsed"] = v }
        if let v = payload[WatchMessageKey.currentMood] as? String { stats["currentMood"] = v }
        if let v = payload[WatchMessageKey.lastInteractionDate] as? Double { stats["lastInteractionDate"] = v }
        if let v = payload[WatchMessageKey.lastNudgeDate] as? Double { stats["lastNudgeDate"] = v }
        return stats
    }
}

// MARK: - WCSessionDelegate

private final class SessionDelegate: NSObject, WCSessionDelegate {
    let onUserInfo: ([String: Any]) -> Void

    init(onUserInfo: @escaping ([String: Any]) -> Void) {
        self.onUserInfo = onUserInfo
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("[PhoneConnectivity] Activation failed: \(error.localizedDescription)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        onUserInfo(userInfo)
    }
}
