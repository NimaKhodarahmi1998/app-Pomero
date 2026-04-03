import SwiftUI
import SwiftData
import WatchKit

struct PersonSpaceView: View {
    let contactName: String

    @Environment(\.modelContext) private var modelContext
    @Query private var allContacts: [Contact]
    @Query private var allAchievements: [Achievement]
    @Query private var allChallenges: [Challenge]

    @State private var showMoodPicker = false
    @State private var showNudgePicker = false
    @State private var showCustomize = false
    @State private var showGoals = false
    @State private var unlockedAchievement: AchievementType?

    @State private var pulseScale: CGFloat = 1.0
    @State private var gradientShift = false
    @State private var particleDrift = false

    private var contact: Contact? {
        allContacts.first { $0.name == contactName }
    }

    private var contactAchievements: [Achievement] {
        allAchievements.filter { $0.contactName == contactName }
    }

    private var dailyChallenges: [Challenge] {
        allChallenges.filter { $0.contactName == contactName && $0.type.period == .daily }
    }

    private var completedDailyCount: Int {
        dailyChallenges.filter { $0.isCompleted }.count
    }

    var body: some View {
        if let contact {
            ZStack {
                background(contact: contact)
                floatingParticles

                VStack(spacing: 0) {

                    Spacer()

                    // Emoji + streak ring
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.10), lineWidth: 3)

                        if contact.streakCount > 0 {
                            Circle()
                                .trim(from: 0, to: min(Double(contact.streakCount) / 7.0, 1.0))
                                .stroke(
                                    LinearGradient(
                                        colors: [.orange, .yellow],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                        }

                        Text(contact.emoji)
                            .font(.system(size: 38))
                            .scaleEffect(pulseScale)
                    }
                    .frame(width: 62, height: 62)

                    Spacer().frame(height: 5)

                    Text(contact.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Spacer().frame(height: 2)

                    // Relationship (left) ←——→ last active (right)
                    HStack {
                        Text(contact.relationship.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let date = contact.lastInteractionDate {
                            Text(date, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.horizontal, 14)

                    Spacer().frame(height: 8)

                    // Info tiles
                    HStack(spacing: 5) {
                        infoTile(action: { showMoodPicker = true }) {
                            if let mood = contact.currentMood {
                                Text(mood.emoji).font(.system(size: 18))
                                Text(mood.label)
                            } else {
                                Image(systemName: "face.smiling")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                                Text("Mood")
                            }
                        }

                        infoTile(action: { showNudgePicker = true }) {
                            Text("👋").font(.system(size: 18))
                            Text(contact.totalNudgesSent > 0 ? "\(contact.totalNudgesSent)" : "Nudge")
                        }

                        infoTile(action: { showGoals = true }) {
                            Text("🎯").font(.system(size: 18))
                            Text(dailyChallenges.isEmpty ? "Goals" : "\(completedDailyCount)/\(dailyChallenges.count)")
                        }
                    }
                    .padding(.horizontal, 6)

                    Spacer()

                    // Style — the only action not covered by the tiles
                    Button { showCustomize = true } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "paintbrush.fill")
                                .font(.system(size: 10))
                            Text("Style")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 6)

                    Spacer().frame(height: 10)
                }

                if let achievement = unlockedAchievement {
                    AchievementUnlockView(type: achievement) {
                        unlockedAchievement = nil
                    }
                }
            }
            .onAppear {
                ensureAchievementsExist()
                startAnimations()
            }
            .sheet(isPresented: $showMoodPicker) {
                MoodSelectionView(contact: contact)
                    .onDisappear { checkAchievements(contact: contact) }
            }
            .sheet(isPresented: $showNudgePicker) {
                SendNudgeView(contact: contact)
                    .onDisappear { checkAchievements(contact: contact) }
            }
            .sheet(isPresented: $showCustomize) {
                CustomizeSpaceView(contact: contact)
            }
            .sheet(isPresented: $showGoals) {
                GoalsView(contact: contact)
            }
        }
    }

    // MARK: - Info tile

    private func infoTile<Content: View>(
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                content()
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Background

    @ViewBuilder
    private func background(contact: Contact) -> some View {
        let base = colorFor(contact.spaceColor)
        let accent = contact.currentMood.map { moodColor($0) } ?? base

        LinearGradient(
            colors: [base.opacity(0.75), accent.opacity(0.35), .black],
            startPoint: gradientShift ? .topLeading : .top,
            endPoint: gradientShift ? .bottomTrailing : .bottom
        )
        .ignoresSafeArea()
        .animation(
            .easeInOut(duration: 4).repeatForever(autoreverses: true),
            value: gradientShift
        )
    }

    // MARK: - Particles

    private var floatingParticles: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let specs: [(CGFloat, CGFloat, CGFloat, Double, CGFloat, Double)] = [
                (0.10, 0.15, 2.5, 0.10,  7, 4.0),
                (0.85, 0.10, 2.0, 0.08, -6, 5.5),
                (0.20, 0.72, 2.0, 0.10,  8, 3.8),
                (0.80, 0.60, 2.5, 0.08, -7, 4.8),
                (0.50, 0.25, 2.0, 0.07,  5, 6.0),
                (0.70, 0.85, 2.5, 0.09, -8, 5.2),
            ]
            ForEach(Array(specs.enumerated()), id: \.offset) { i, s in
                Circle()
                    .fill(.white.opacity(s.3))
                    .frame(width: s.2, height: s.2)
                    .offset(x: w * s.0, y: (h * s.1) + (particleDrift ? s.4 : -s.4))
                    .animation(
                        .easeInOut(duration: s.5).repeatForever(autoreverses: true),
                        value: particleDrift
                    )
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Helpers

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            pulseScale = 1.06
        }
        gradientShift = true
        particleDrift = true
    }

    private func ensureAchievementsExist() {
        guard let contact else { return }
        if contactAchievements.isEmpty {
            AchievementService.createAll(for: contact.name, context: modelContext)
        }
    }

    private func checkAchievements(contact: Contact) {
        if let unlocked = AchievementService.checkAll(for: contact, context: modelContext) {
            unlockedAchievement = unlocked
        }
    }

    private func moodColor(_ mood: MoodType) -> Color {
        switch mood {
        case .happy:     return .yellow
        case .excited:   return .orange
        case .loved:     return .pink
        case .grateful:  return .mint
        case .calm:      return .cyan
        case .bored:     return .gray
        case .anxious:   return .purple
        case .stressed:  return .red
        case .sad:       return .indigo
        case .lonely:    return .blue
        case .tired:     return Color(white: 0.45)
        case .angry:     return Color(red: 0.85, green: 0.15, blue: 0.1)
        case .energetic: return .yellow
        }
    }
}

#Preview {
    PersonSpaceView(contactName: "Alex")
}
