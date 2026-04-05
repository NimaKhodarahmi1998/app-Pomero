import SwiftUI
import SwiftData
import WatchKit

struct MoodSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    var contact: Contact

    @State private var selectedIndex = 0.0
    @State private var saved = false

    private let moods = MoodType.allCases.filter { !$0.isLegacy }

    private var currentMood: MoodType {
        let count = moods.count
        let index = Int(round(selectedIndex)) % count
        let safeIndex = index < 0 ? index + count : index
        return moods[safeIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("How do you feel?")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 10)

            Spacer()

            Text(currentMood.emoji)
                .font(.system(size: 44))
                .id(currentMood)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(duration: 0.3), value: currentMood)

            Spacer().frame(height: 6)

            Text(currentMood.label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(moodColor)
                .animation(.easeInOut, value: currentMood)

            Spacer().frame(height: 8)

            HStack(spacing: 5) {
                ForEach(Array(moods.enumerated()), id: \.element.id) { _, mood in
                    Circle()
                        .fill(currentMood == mood ? moodColor : .secondary.opacity(0.3))
                        .frame(width: currentMood == mood ? 7 : 4, height: currentMood == mood ? 7 : 4)
                        .animation(.spring(duration: 0.2), value: currentMood)
                }
            }

            Spacer()

            Button("Set Mood") { saveMood() }
                .tint(moodColor)
                .padding(.bottom, 4)
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
            if saved { savedOverlay }
        }
    }

    private var moodColor: Color {
        switch currentMood {
        case .happy:    return .yellow
        case .excited:  return .orange
        case .loved:    return .pink
        case .grateful: return .mint
        case .calm:     return .cyan
        case .bored:    return .gray
        case .anxious:  return .purple
        case .stressed: return .red
        case .sad:      return .indigo
        case .lonely:   return .blue
        case .tired:    return Color(white: 0.45)
        case .angry:    return Color(red: 0.85, green: 0.15, blue: 0.1)
        case .energetic: return .yellow
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
        Task {
            try? await Task.sleep(for: .seconds(1))
            saved = false
            dismiss()
        }
    }

    private var savedOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)

            VStack(spacing: 8) {
                Text(currentMood.emoji)
                    .font(.system(size: 40))
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.green)
            }
            .padding(20)
            .glassEffect(in: RoundedRectangle(cornerRadius: 20))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: saved)
    }
}

#Preview {
    MoodSelectionView(contact: Contact(name: "Alex", relationship: .partner))
}
