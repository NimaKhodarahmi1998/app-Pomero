import SwiftUI

@Observable
final class CloudKitService {
    static let shared = CloudKitService()

    // Current state
    var connectionCode: String?
    var partnerMood: MoodType?
    var partnerName: String?
    var isConnected = false
    var error: String?

    // Confirmation state
    var pendingPartnerName: String?
    var waitingForAcceptance = false

    private init() {
        // Restore saved connection
        if let code = UserDefaults.standard.string(forKey: "connectionCode"),
           UserDefaults.standard.bool(forKey: "isConnected") {
            connectionCode = code
            partnerName = UserDefaults.standard.string(forKey: "partnerName")
            isConnected = true

            // Restore last known partner mood
            if let moodRaw = UserDefaults.standard.string(forKey: "partnerMood") {
                partnerMood = MoodType(rawValue: moodRaw)
            }
        }
    }

    // MARK: - Create Connection (offline-first for now)

    func createConnection(myName: String) async {
        let code = generateCode()
        connectionCode = code
        UserDefaults.standard.set(code, forKey: "connectionCode")
        UserDefaults.standard.set(myName, forKey: "myName")
        UserDefaults.standard.set("userA", forKey: "myRole")
        error = nil
    }

    // MARK: - Join Connection (simulated locally)

    func joinConnection(code: String, myName: String) async {
        guard code.count >= 6 else {
            error = "Code must be 6 characters."
            return
        }

        connectionCode = code.uppercased()
        partnerName = "Partner" // Placeholder until CloudKit is live
        UserDefaults.standard.set(code.uppercased(), forKey: "connectionCode")
        UserDefaults.standard.set(myName, forKey: "myName")
        UserDefaults.standard.set("userB", forKey: "myRole")
        isConnected = true
        UserDefaults.standard.set(true, forKey: "isConnected")
        UserDefaults.standard.set("Partner", forKey: "partnerName")
        error = nil
    }

    // MARK: - Accept (Person A confirms Person B)

    func acceptConnection() async {
        partnerName = pendingPartnerName ?? "Partner"
        pendingPartnerName = nil
        isConnected = true
        UserDefaults.standard.set(true, forKey: "isConnected")
        UserDefaults.standard.set(partnerName, forKey: "partnerName")
    }

    func declineConnection() async {
        pendingPartnerName = nil
    }

    // MARK: - Send Mood (stores locally, ready for CloudKit later)

    func sendMood(_ mood: MoodType) async {
        // When CloudKit is back, this will sync to the cloud.
        // For now, store locally so the UI works.
        UserDefaults.standard.set(mood.rawValue, forKey: "myMood")
    }

    // MARK: - Simulate receiving partner mood (for testing)

    func simulatePartnerMood(_ mood: MoodType) {
        partnerMood = mood
        UserDefaults.standard.set(mood.rawValue, forKey: "partnerMood")
    }

    // MARK: - Disconnect

    func disconnect() {
        connectionCode = nil
        partnerMood = nil
        partnerName = nil
        isConnected = false
        pendingPartnerName = nil
        waitingForAcceptance = false
        for key in ["connectionCode", "myRole", "myName", "isConnected", "partnerName", "partnerMood", "myMood"] {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: - Helpers

    private func generateCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}
