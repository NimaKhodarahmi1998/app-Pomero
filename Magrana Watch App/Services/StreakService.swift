import Foundation
import SwiftData

enum StreakService {
    /// Call this whenever an interaction happens (mood set, nudge sent)
    static func recordInteraction(for contact: Contact) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        if let lastDate = contact.lastInteractionDate {
            let lastDay = calendar.startOfDay(for: lastDate)

            if lastDay == today {
                // Already interacted today — no change
                return
            }

            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if lastDay == yesterday {
                // Consecutive day — increment streak
                contact.streakCount += 1
            } else {
                // Streak broken — reset to 1
                contact.streakCount = 1
            }
        } else {
            // First interaction ever
            contact.streakCount = 1
        }

        contact.lastInteractionDate = .now
    }
}
