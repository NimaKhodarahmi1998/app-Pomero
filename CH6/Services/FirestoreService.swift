import Foundation
import FirebaseAuth
import FirebaseFirestore

enum FirestoreService {

    private static let db = Firestore.firestore()

    private static func userDoc() -> DocumentReference? {
        guard let uid = AuthService.shared.currentUser?.uid else { return nil }
        return db.collection("users").document(uid)
    }

    private static func contactDoc(_ contactName: String) -> DocumentReference? {
        userDoc()?.collection("contacts").document(contactName)
    }

    // MARK: - Profile

    static func setProfile(_ fields: [String: Any]) async throws {
        guard let doc = userDoc() else { return }
        try await doc.setData(fields, merge: true)
    }

    // MARK: - Contacts

    static func createContact(
        name: String,
        relationship: String,
        emoji: String,
        spaceColor: String,
        challengeTypes: [String]
    ) async throws {
        guard let doc = contactDoc(name) else { return }

        // Contact info
        try await doc.setData([
            "name": name,
            "relationship": relationship,
            "emoji": emoji,
            "spaceColor": spaceColor,
            "streakCount": 0,
            "totalNudgesSent": 0,
            "totalMoodsSet": 0,
            "uniqueMoodsUsed": [String](),
            "createdAt": FieldValue.serverTimestamp()
        ])

        // Initial challenges
        let batch = db.batch()
        for type in challengeTypes {
            let ref = doc.collection("challenges").document(type)
            batch.setData([
                "progress": 0,
                "isCompleted": false,
                "startDate": Date().timeIntervalSince1970
            ], forDocument: ref)
        }
        try await batch.commit()

        // Initial achievements — create all types as locked
        let achievementBatch = db.batch()
        let achievementTypes = [
            "firstSpark", "growing", "rooted", "unbreakable",
            "firstWave", "penPal", "alwaysOn", "orbiting",
            "firstFeeling", "fullSpectrum", "openBook",
            "dayOne", "oneMonth", "anniversary",
            "firstSong", "djFriend",
            "challengeCreator", "customChampion",
            "nightOwl", "earlyBird", "onFire", "soulmate"
        ]
        for type in achievementTypes {
            let ref = doc.collection("achievements").document(type)
            achievementBatch.setData([
                "isUnlocked": false
            ], forDocument: ref)
        }
        try await achievementBatch.commit()
    }

    static func updateContact(name: String, fields: [String: Any]) async throws {
        guard let doc = contactDoc(name) else { return }
        try await doc.updateData(fields)
    }

    static func deleteContact(name: String) async throws {
        guard let doc = contactDoc(name) else { return }

        // Delete subcollections
        let subcollections = ["moods", "nudges", "songs", "challenges", "customChallenges", "achievements"]
        for sub in subcollections {
            let snapshot = try await doc.collection(sub).getDocuments()
            let batch = db.batch()
            for document in snapshot.documents {
                batch.deleteDocument(document.reference)
            }
            try await batch.commit()
        }

        // Delete contact document
        try await doc.delete()
    }

    // MARK: - Nudges

    static func addNudge(
        contactName: String,
        type: String,
        timestamp: Double,
        isSent: Bool
    ) async throws {
        guard let doc = contactDoc(contactName) else { return }
        try await doc.collection("nudges").addDocument(data: [
            "type": type,
            "timestamp": timestamp,
            "isSent": isSent
        ])
    }

    // MARK: - Moods

    static func addMood(
        contactName: String,
        type: String,
        timestamp: Double,
        note: String?
    ) async throws {
        guard let doc = contactDoc(contactName) else { return }
        var data: [String: Any] = [
            "type": type,
            "timestamp": timestamp
        ]
        if let note { data["note"] = note }
        try await doc.collection("moods").addDocument(data: data)
    }

    // MARK: - Contact Stats

    static func updateContactStats(contactName: String, stats: [String: Any]) async throws {
        guard let doc = contactDoc(contactName) else { return }
        try await doc.updateData(stats)
    }

    // MARK: - Songs

    static func addSong(
        contactName: String,
        songTitle: String,
        artistName: String,
        albumTitle: String,
        appleMusicURL: String?,
        timestamp: Double
    ) async throws {
        guard let doc = contactDoc(contactName) else { return }
        var data: [String: Any] = [
            "songTitle": songTitle,
            "artistName": artistName,
            "albumTitle": albumTitle,
            "timestamp": timestamp
        ]
        if let appleMusicURL { data["appleMusicURL"] = appleMusicURL }
        try await doc.collection("songs").addDocument(data: data)
    }

    // MARK: - Challenges

    static func updateChallenge(
        contactName: String,
        type: String,
        progress: Int,
        isCompleted: Bool,
        startDate: Double
    ) async throws {
        guard let doc = contactDoc(contactName) else { return }
        try await doc.collection("challenges").document(type).setData([
            "progress": progress,
            "isCompleted": isCompleted,
            "startDate": startDate
        ])
    }

    // MARK: - Custom Challenges

    static func createCustomChallenge(
        contactName: String,
        title: String,
        createdAt: Double
    ) async throws {
        guard let doc = contactDoc(contactName) else { return }
        try await doc.collection("customChallenges").addDocument(data: [
            "title": title,
            "isCompleted": false,
            "createdAt": createdAt
        ])
    }

    static func updateCustomChallenge(
        contactName: String,
        title: String,
        isCompleted: Bool,
        completedAt: Double?
    ) async throws {
        guard let doc = contactDoc(contactName) else { return }
        let snapshot = try await doc.collection("customChallenges")
            .whereField("title", isEqualTo: title)
            .getDocuments()
        guard let document = snapshot.documents.first else { return }
        var data: [String: Any] = ["isCompleted": isCompleted]
        if let completedAt {
            data["completedAt"] = completedAt
        } else {
            data["completedAt"] = FieldValue.delete()
        }
        try await document.reference.updateData(data)
    }

    // MARK: - Achievements

    static func updateAchievement(
        contactName: String,
        type: String,
        isUnlocked: Bool,
        unlockedAt: Double?
    ) async throws {
        guard let doc = contactDoc(contactName) else { return }
        var data: [String: Any] = ["isUnlocked": isUnlocked]
        if let unlockedAt { data["unlockedAt"] = unlockedAt }
        try await doc.collection("achievements").document(type).setData(data)
    }

    // MARK: - Full Sync (Read All Data)

    static func fetchAllContacts() async throws -> [[String: Any]] {
        guard let userRef = userDoc() else { return [] }

        let contactsSnapshot = try await userRef.collection("contacts").getDocuments()
        var contacts: [[String: Any]] = []

        for contactDoc in contactsSnapshot.documents {
            var contactData = contactDoc.data()
            contactData["name"] = contactDoc.documentID

            // Fetch challenges
            let challengesSnap = try await contactDoc.reference.collection("challenges").getDocuments()
            contactData["challenges"] = challengesSnap.documents.map { doc in
                var d = doc.data()
                d["type"] = doc.documentID
                return d
            }

            // Fetch custom challenges
            let customSnap = try await contactDoc.reference.collection("customChallenges").getDocuments()
            contactData["customChallenges"] = customSnap.documents.map { $0.data() }

            // Fetch achievements
            let achievementsSnap = try await contactDoc.reference.collection("achievements").getDocuments()
            contactData["achievements"] = achievementsSnap.documents.map { doc in
                var d = doc.data()
                d["type"] = doc.documentID
                return d
            }

            contacts.append(contactData)
        }

        return contacts
    }
}
