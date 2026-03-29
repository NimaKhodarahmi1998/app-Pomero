import SwiftUI
import SwiftData
import WatchKit

struct MoodSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    var contact: Contact

    @State private var selectedIndex = 0.0
    @State private var saved = false

    private let moods = MoodType.allCases

    private var currentMood: MoodType {
        let count = moods.count
        let index = Int(round(selectedIndex)) % count
        let safeIndex = index < 0 ? index + count : index
        return moods[safeIndex]
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("How do you feel?")
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Big mood display
            Text(currentMood.emoji)
                .font(.system(size: 64))
                .id(currentMood)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(duration: 0.3), value: currentMood)

            Text(currentMood.label)
                .font(.headline)
                .foregroundStyle(moodColor)
                .id(currentMood.label)
                .animation(.easeInOut, value: currentMood)

            // Dots indicator
            HStack(spacing: 6) {
                ForEach(Array(moods.enumerated()), id: \.element.id) { index, mood in
                    Circle()
                        .fill(currentMood == mood ? moodColor : .white.opacity(0.3))
                        .frame(width: currentMood == mood ? 8 : 5, height: currentMood == mood ? 8 : 5)
                        .animation(.spring(duration: 0.2), value: currentMood)
                }
            }
            .padding(.vertical, 4)

            Button("Set Mood") {
                saveMood()
            }
            .tint(moodColor)
        }
        .focusable()
        .digitalCrownRotation(
            $selectedIndex,
            from: 0,
            through: Double(moods.count - 1),
            by: 1,
            sensitivity: .low,
            isContinuous: true
        )
        .overlay {
            if saved {
                savedOverlay
            }
        }
    }

    private var moodColor: Color {
        switch currentMood {
        case .happy: .yellow
        case .calm: .cyan
        case .stressed: .red
        case .sad: .indigo
        case .energetic: .orange
        case .tired: .gray
        }
    }

    private func saveMood() {
        let entry = MoodEntry(type: currentMood, contact: contact)
        modelContext.insert(entry)
        contact.currentMood = currentMood
        contact.totalMoodsSet += 1

        if !contact.uniqueMoodsUsed.contains(currentMood.rawValue) {
            contact.uniqueMoodsUsed.append(currentMood.rawValue)
        }

        StreakService.recordInteraction(for: contact)
        ChallengeService.recordMoodSet(for: contact, context: modelContext)
        WKInterfaceDevice.current().play(.success)

        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            saved = false
            dismiss()
        }
    }

    private var savedOverlay: some View {
        VStack(spacing: 6) {
            Text(currentMood.emoji)
                .font(.system(size: 48))
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .transition(.opacity)
        .animation(.easeInOut, value: saved)
    }
}

#Preview {
    MoodSelectionView(contact: Contact(name: "Alex", relationship: .partner))
}
