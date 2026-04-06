import Foundation
import SwiftData
import WatchConnectivity

@MainActor
@Observable
final class WatchConnectivityService: NSObject {
    static let shared = WatchConnectivityService()

    // Auth state received from iPhone
    var isPhoneSignedIn = false
    var phoneUID: String?
    var phoneEmail: String?

    // Sync state
    var isSyncing = false
    var lastSyncDate: Date?

    var isReachable: Bool { session.isReachable }

    var modelContainer: ModelContainer?

    private let session = WCSession.default
    private var delegate: SessionDelegate?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let del = SessionDelegate(
            onApplicationContext: { [weak self] context in
                Task { @MainActor in
                    self?.handleApplicationContext(context)
                }
            },
            onUserInfo: { [weak self] userInfo in
                Task { @MainActor in
                    self?.handleUserInfo(userInfo)
                }
            }
        )
        self.delegate = del
        session.delegate = del
        session.activate()
    }

    // MARK: - Send to Phone

    func send(_ message: [String: Any]) {
        guard WCSession.isSupported() else { return }
        session.transferUserInfo(message)
    }

    // MARK: - Receive Auth State from Phone

    private func handleApplicationContext(_ context: [String: Any]) {
        isPhoneSignedIn = context[WatchMessageKey.isSignedIn] as? Bool ?? false
        phoneUID = context[WatchMessageKey.uid] as? String
        phoneEmail = context[WatchMessageKey.email] as? String
    }

    // MARK: - Receive Messages from Phone

    private func handleUserInfo(_ message: [String: Any]) {
        guard let (action, payload) = WatchMessage.parse(message) else { return }

        switch action {
        case .fullSync:
            handleFullSync(payload)
        default:
            break
        }
    }

    // MARK: - Full Sync Handler

    private func handleFullSync(_ payload: [String: Any]) {
        guard let container = modelContainer else {
            print("[WatchConnectivity] No ModelContainer set — cannot sync")
            return
        }
        guard let contactDicts = payload[WatchMessageKey.contacts] as? [[String: Any]] else {
            print("[WatchConnectivity] Full sync payload missing contacts")
            return
        }

        isSyncing = true

        let context = ModelContext(container)

        for contactDict in contactDicts {
            guard let name = contactDict["name"] as? String,
                  let relationshipRaw = contactDict["relationship"] as? String,
                  let relationship = RelationshipType(rawValue: relationshipRaw) else { continue }

            let emoji = contactDict["emoji"] as? String ?? "❤️"
            let spaceColorRaw = contactDict["spaceColor"] as? String ?? "purple"
            let spaceColor = SpaceColor(rawValue: spaceColorRaw) ?? .purple

            // Check if contact already exists
            let predicate = #Predicate<Contact> { $0.name == name }
            let existing = try? context.fetch(FetchDescriptor<Contact>(predicate: predicate))

            let contact: Contact
            if let found = existing?.first {
                // Update existing
                found.relationship = relationship
                found.emoji = emoji
                found.spaceColor = spaceColor
                contact = found
            } else {
                // Create new
                contact = Contact(name: name, relationship: relationship, emoji: emoji, spaceColor: spaceColor)
                context.insert(contact)
            }

            // Sync stats
            if let v = contactDict["streakCount"] as? Int { contact.streakCount = v }
            if let v = contactDict["totalNudgesSent"] as? Int { contact.totalNudgesSent = v }
            if let v = contactDict["totalMoodsSet"] as? Int { contact.totalMoodsSet = v }
            if let v = contactDict["uniqueMoodsUsed"] as? [String] { contact.uniqueMoodsUsed = v }
            if let v = contactDict["currentMood"] as? String { contact.currentMood = MoodType(rawValue: v) }
            if let v = contactDict["lastInteractionDate"] as? Double { contact.lastInteractionDate = Date(timeIntervalSince1970: v) }
            if let v = contactDict["lastNudgeDate"] as? Double { contact.lastNudgeDate = Date(timeIntervalSince1970: v) }

            // Sync challenges
            if let challengeDicts = contactDict["challenges"] as? [[String: Any]] {
                for chDict in challengeDicts {
                    guard let typeRaw = chDict["type"] as? String,
                          let type = ChallengeType(rawValue: typeRaw) else { continue }

                    let progress = chDict["progress"] as? Int ?? 0
                    let isCompleted = chDict["isCompleted"] as? Bool ?? false
                    let startDate = (chDict["startDate"] as? Double).map { Date(timeIntervalSince1970: $0) } ?? .now

                    let chPredicate = #Predicate<Challenge> { $0.contactName == name && $0.type == type }
                    let existingCh = try? context.fetch(FetchDescriptor<Challenge>(predicate: chPredicate))

                    if let found = existingCh?.first {
                        found.progress = progress
                        found.isCompleted = isCompleted
                        found.startDate = startDate
                    } else {
                        let ch = Challenge(type: type, contactName: name, startDate: startDate)
                        ch.progress = progress
                        ch.isCompleted = isCompleted
                        context.insert(ch)
                    }
                }
            }

            // Sync custom challenges
            if let customDicts = contactDict["customChallenges"] as? [[String: Any]] {
                for ccDict in customDicts {
                    guard let title = ccDict["title"] as? String else { continue }

                    let isCompleted = ccDict["isCompleted"] as? Bool ?? false
                    let createdAt = (ccDict["createdAt"] as? Double).map { Date(timeIntervalSince1970: $0) } ?? .now
                    let completedAt = (ccDict["completedAt"] as? Double).map { Date(timeIntervalSince1970: $0) }

                    let ccPredicate = #Predicate<CustomChallenge> { $0.contactName == name && $0.title == title }
                    let existingCC = try? context.fetch(FetchDescriptor<CustomChallenge>(predicate: ccPredicate))

                    if let found = existingCC?.first {
                        found.isCompleted = isCompleted
                        found.completedAt = completedAt
                    } else {
                        let cc = CustomChallenge(title: title, contactName: name)
                        cc.isCompleted = isCompleted
                        cc.createdAt = createdAt
                        cc.completedAt = completedAt
                        context.insert(cc)
                    }
                }
            }

            // Sync achievements
            if let achDicts = contactDict["achievements"] as? [[String: Any]] {
                for achDict in achDicts {
                    guard let typeRaw = achDict["type"] as? String,
                          let type = AchievementType(rawValue: typeRaw) else { continue }

                    let isUnlocked = achDict["isUnlocked"] as? Bool ?? false
                    let unlockedAt = (achDict["unlockedAt"] as? Double).map { Date(timeIntervalSince1970: $0) }

                    let achPredicate = #Predicate<Achievement> { $0.contactName == name && $0.type == type }
                    let existingAch = try? context.fetch(FetchDescriptor<Achievement>(predicate: achPredicate))

                    if let found = existingAch?.first {
                        found.isUnlocked = isUnlocked
                        found.unlockedAt = unlockedAt
                    } else {
                        let ach = Achievement(type: type, contactName: name)
                        ach.isUnlocked = isUnlocked
                        ach.unlockedAt = unlockedAt
                        context.insert(ach)
                    }
                }
            }
        }

        do {
            try context.save()
            lastSyncDate = .now
            print("[WatchConnectivity] Full sync applied: \(contactDicts.count) contacts")
        } catch {
            print("[WatchConnectivity] Failed to save sync data: \(error.localizedDescription)")
        }

        isSyncing = false
    }
}

// MARK: - WCSessionDelegate (non-isolated wrapper)

private final class SessionDelegate: NSObject, WCSessionDelegate {
    let onApplicationContext: ([String: Any]) -> Void
    let onUserInfo: ([String: Any]) -> Void

    init(
        onApplicationContext: @escaping ([String: Any]) -> Void,
        onUserInfo: @escaping ([String: Any]) -> Void
    ) {
        self.onApplicationContext = onApplicationContext
        self.onUserInfo = onUserInfo
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("[WatchConnectivity] Activation failed: \(error.localizedDescription)")
        }
        // Read any existing application context on activation
        if !session.receivedApplicationContext.isEmpty {
            onApplicationContext(session.receivedApplicationContext)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        onApplicationContext(applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        onUserInfo(userInfo)
    }
}
