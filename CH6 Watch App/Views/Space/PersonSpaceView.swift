import SwiftUI
import SwiftData
import WatchKit

struct PersonSpaceView: View {
    @Environment(\.modelContext) private var modelContext
    var contact: Contact

    @State private var showMoodPicker = false
    @State private var showNudgePicker = false
    @State private var showCustomize = false
    @State private var showChallenges = false
    @State private var breathe = false

    @Query(sort: \NudgeEntry.timestamp, order: .reverse)
    private var allNudges: [NudgeEntry]

    @Query(sort: \MoodEntry.timestamp, order: .reverse)
    private var allMoods: [MoodEntry]

    private var recentNudges: [NudgeEntry] {
        allNudges.filter { $0.contactName == contact.name }
    }

    private var moodHistory: [MoodEntry] {
        allMoods.filter { $0.contact?.name == contact.name }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Breathing avatar emoji
                    Text(contact.emoji)
                        .font(.system(size: 48))
                        .scaleEffect(breathe ? 1.08 : 0.95)
                        .animation(
                            .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                            value: breathe
                        )
                        .onAppear { breathe = true }

                    // Name
                    Text(contact.displayName)
                        .font(.headline)
                        .foregroundStyle(.white)

                    // Streak
                    if contact.streakCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text("\(contact.streakCount)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }

                    // Current mood
                    if let mood = contact.currentMood {
                        VStack(spacing: 2) {
                            Text(mood.emoji)
                                .font(.system(size: 32))
                            Text(mood.label)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }

                    // Mood history dots (last 7)
                    if !moodHistory.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(moodHistory.prefix(7)) { entry in
                                Text(entry.type.emoji)
                                    .font(.system(size: 10))
                            }
                        }
                    }

                    // Last nudge exchange
                    if let lastNudge = recentNudges.first {
                        HStack(spacing: 4) {
                            Text(lastNudge.isSent ? "You:" : "\(contact.displayName):")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.5))
                            Text(lastNudge.type.emoji)
                                .font(.system(size: 12))
                            Text(lastNudge.timestamp, style: .relative)
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }

                    // Action buttons
                    HStack(spacing: 8) {
                        spaceButton(icon: "face.smiling", label: "Mood") {
                            showMoodPicker = true
                        }
                        spaceButton(icon: "hand.tap", label: "Nudge") {
                            showNudgePicker = true
                        }
                        spaceButton(icon: "trophy", label: "Goals") {
                            showChallenges = true
                        }
                    }
                }
                .padding(.horizontal)
            }
            .background(moodReactiveBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCustomize = true
                    } label: {
                        Image(systemName: "paintbrush")
                            .font(.caption2)
                    }
                }
            }
            .sheet(isPresented: $showMoodPicker) {
                MoodSelectionView(contact: contact)
            }
            .sheet(isPresented: $showNudgePicker) {
                SendNudgeView(contact: contact)
            }
            .sheet(isPresented: $showCustomize) {
                CustomizeSpaceView(contact: contact)
            }
            .sheet(isPresented: $showChallenges) {
                ChallengeListView(contact: contact)
            }
        }
    }

    // MARK: - Components

    private func spaceButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.body)
                Text(label)
                    .font(.system(size: 8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Mood-reactive background

    private var moodReactiveBackground: some View {
        let baseColor = spaceUIColor
        let moodColors = moodAccentColors

        return ZStack {
            LinearGradient(
                colors: [
                    moodColors.0.opacity(0.6),
                    baseColor.opacity(0.4),
                    moodColors.1.opacity(0.2),
                    .black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(moodColors.0.opacity(0.15))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(y: -50)
                .scaleEffect(breathe ? 1.1 : 0.9)
                .animation(
                    .easeInOut(duration: 3).repeatForever(autoreverses: true),
                    value: breathe
                )
        }
        .ignoresSafeArea()
    }

    private var moodAccentColors: (Color, Color) {
        guard let mood = contact.currentMood else {
            return (spaceUIColor, spaceUIColor)
        }
        switch mood {
        case .happy: return (.yellow, .orange)
        case .calm: return (.cyan, .blue)
        case .stressed: return (.red, .orange)
        case .sad: return (.indigo, .purple)
        case .energetic: return (.orange, .yellow)
        case .tired: return (.gray, .blue)
        }
    }

    private var spaceUIColor: Color {
        switch contact.spaceColor {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .mint: .mint
        case .teal: .teal
        case .cyan: .cyan
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        }
    }
}

#Preview {
    PersonSpaceView(contact: Contact(name: "Alex", relationship: .partner, emoji: "🦊", spaceColor: .purple))
}
