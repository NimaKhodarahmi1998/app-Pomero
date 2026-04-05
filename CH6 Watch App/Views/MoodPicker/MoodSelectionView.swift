import SwiftUI
import SwiftData
import WatchKit

struct MoodSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    var contact: Contact

    @State private var selectedIndex = 0.0
    @State private var saved = false
    @FocusState private var isFocused: Bool

    private let moods = MoodType.allCases.filter { !$0.isLegacy }

    private var scale: CGFloat {
        let b = WKInterfaceDevice.current().screenBounds
        guard b.width > 0, b.height > 0 else { return 1.0 }
        return min(b.width / 198.0, b.height / 242.0)
    }

    private var currentMood: MoodType {
        let count = moods.count
        let index = Int(round(selectedIndex)) % count
        let safeIndex = index < 0 ? index + count : index
        return moods[safeIndex]
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

    var body: some View {
        ZStack {
            // Mood-tinted background
            RadialGradient(
                colors: [moodColor.opacity(0.35), Color.black.opacity(0.85)],
                center: .center,
                startRadius: 10,
                endRadius: 120
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.4), value: currentMood)

            VStack(spacing: 0) {
                // Header
                Text("How do you feel?")
                    .font(.system(size: 11 * scale, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8 * scale)

                Spacer()

                // Emoji + glass card
                ZStack {
                    RoundedRectangle(cornerRadius: 22 * scale)
                        .fill(.ultraThinMaterial)
                        .frame(width: 76 * scale, height: 76 * scale)
                        .shadow(color: moodColor.opacity(0.45), radius: 12)
                        .animation(.easeInOut(duration: 0.4), value: currentMood)

                    Text(currentMood.emoji)
                        .font(.system(size: 38 * scale))
                        .id(currentMood)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.6).combined(with: .opacity),
                                removal: .scale(scale: 1.3).combined(with: .opacity)
                            )
                        )
                        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: currentMood)
                }

                Spacer().frame(height: 10 * scale)

                // Mood label pill
                Text(currentMood.label)
                    .font(.system(size: 13 * scale, weight: .semibold))
                    .foregroundStyle(moodColor)
                    .padding(.horizontal, 12 * scale)
                    .padding(.vertical, 5 * scale)
                    .glassEffect(.regular, in: Capsule())
                    .animation(.easeInOut(duration: 0.3), value: currentMood)

                Spacer().frame(height: 10 * scale)

                // Dot indicators
                HStack(spacing: 4) {
                    ForEach(Array(moods.enumerated()), id: \.element.id) { _, mood in
                        Capsule()
                            .fill(currentMood == mood ? moodColor : Color.white.opacity(0.2))
                            .frame(
                                width: currentMood == mood ? 12 * scale : 4 * scale,
                                height: 4 * scale
                            )
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentMood)
                    }
                }

                Spacer()

                // Set Mood button
                Button { saveMood() } label: {
                    Text("Set Mood")
                        .font(.system(size: 13 * scale, weight: .semibold))
                        .foregroundStyle(moodColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8 * scale)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12 * scale))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10 * scale)
                .padding(.bottom, 6 * scale)
            }
        }
        .presentationBackground(.clear)
        .focusable()
        .focused($isFocused)
        .digitalCrownRotation(
            $selectedIndex,
            from: 0,
            through: Double(moods.count - 1),
            by: 1,
            sensitivity: .low,
            isContinuous: true
        )
        .onAppear { isFocused = true }
        .overlay {
            if saved { savedOverlay }
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
            Color.black.opacity(0.3)
            VStack(spacing: 8) {
                Text(currentMood.emoji)
                    .font(.system(size: 40))
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(moodColor)
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
