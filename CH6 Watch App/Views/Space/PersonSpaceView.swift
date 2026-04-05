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

    // Per-ring pulse scale + burst
    @State private var streakRingScale: CGFloat = 1.0
    @State private var nudgeRingScale: CGFloat = 1.0
    @State private var dailyRingScale: CGFloat = 1.0
    @State private var burstColor: Color? = nil
    @State private var burstID = UUID()

    private var contact: Contact? {
        allContacts.first { $0.name == contactName }
    }

    private var contactAchievements: [Achievement] {
        allAchievements.filter { $0.contactName == contactName }
    }

    // MARK: - Ring progress values

    private func streakProgress(_ contact: Contact) -> Double {
        min(Double(contact.streakCount) / 7.0, 1.0)
    }

    private var weeklyNudgeProgress: Double {
        guard let c = allChallenges.first(where: { $0.contactName == contactName && $0.type == .fiveNudges }) else { return 0 }
        return min(Double(c.progress) / Double(c.type.target), 1.0)
    }

    private var dailyChallengeProgress: Double {
        let daily = allChallenges.filter { $0.contactName == contactName && $0.type.period == .daily }
        guard !daily.isEmpty else { return 0 }
        return Double(daily.filter { $0.isCompleted }.count) / Double(daily.count)
    }

    private var nudgeStatText: String {
        guard let c = allChallenges.first(where: { $0.contactName == contactName && $0.type == .fiveNudges }) else { return "–" }
        return "\(c.progress)/\(c.type.target)"
    }

    private var dailyStatText: String {
        let daily = allChallenges.filter { $0.contactName == contactName && $0.type.period == .daily }
        guard !daily.isEmpty else { return "–" }
        return "\(daily.filter { $0.isCompleted }.count)/\(daily.count)"
    }

    // Scale factor capped by both screen dimensions so layout always fits in one screen.
    // Baseline: 45mm = 198 × 242 pt. Taking the min of both axes handles every size:
    //   40mm SE  → 0.81×   41mm S7-9 → 0.89×   44mm SE → 0.93×
    //   45mm S7-9 → 1.00×  Ultra 49mm → 1.04×
    private var scale: CGFloat {
        let b = WKInterfaceDevice.current().screenBounds
        guard b.width > 0, b.height > 0 else { return 1.0 }
        return min(b.width / 198.0, b.height / 242.0)
    }

    // MARK: - Body

    var body: some View {
        if let contact {
            ZStack {
                background(contact: contact)
                floatingParticles

                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    // Rings with stat legend left, customize button right
                    HStack(alignment: .center, spacing: 8 * scale) {
                        ringLegend(contact: contact)
                            .frame(width: 36 * scale, alignment: .trailing)
                        activityRings(contact: contact)
                        iconButton(action: { showCustomize = true }) {
                            Image(systemName: "paintbrush.fill")
                                .font(.system(size: 13 * scale, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 36 * scale)
                    }

                    Spacer().frame(height: 4 * scale)

                    Text(contact.displayName)
                        .font(.system(size: 17 * scale, weight: .semibold))

                    Spacer().frame(height: 1 * scale)

                    // Compact single-line: relationship · time
                    HStack(spacing: 4) {
                        Text(contact.relationship.label)
                            .foregroundStyle(.secondary)

                        if let date = contact.lastInteractionDate {
                            Text("·").foregroundStyle(.tertiary)
                            Text(date, style: .relative)
                                .foregroundStyle(.tertiary)
                        } else {
                            Text("·").foregroundStyle(.tertiary)
                            Text("say hi first 👋")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .font(.system(size: 11 * scale))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                    Spacer().frame(height: 6 * scale)

                    // Three circle action buttons
                    HStack(spacing: 0) {
                        Spacer()
                        circleAction(label: contact.currentMood?.label ?? "Mood", action: { showMoodPicker = true }) {
                            if let mood = contact.currentMood {
                                Text(mood.emoji).font(.system(size: 20 * scale))
                            } else {
                                Image(systemName: "face.smiling")
                                    .font(.system(size: 18 * scale, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        circleAction(label: "Nudge", action: { showNudgePicker = true }) {
                            Image(systemName: "hand.tap")
                                .font(.system(size: 18 * scale, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        circleAction(label: "Goals", action: { showGoals = true }) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 18 * scale, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }

                    // Fixed gap so tab indicators never overlap buttons
                    Color.clear.frame(height: 36 * scale)
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
            .onChange(of: streakProgress(contact)) { old, new in
                if old < 1.0 && new >= 1.0 { ringCompleted(ring: 0) }
            }
            .onChange(of: weeklyNudgeProgress) { old, new in
                if old < 1.0 && new >= 1.0 { ringCompleted(ring: 1) }
            }
            .onChange(of: dailyChallengeProgress) { old, new in
                if old < 1.0 && new >= 1.0 { ringCompleted(ring: 2) }
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

    // MARK: - Activity rings

    private func activityRings(contact: Contact) -> some View {
        let outer  = 82 * scale
        let middle = 65 * scale
        let inner  = 50 * scale
        return ZStack {
            nativeRing(diameter: outer,  progress: streakProgress(contact),  colors: [.orange, .yellow])
                .scaleEffect(streakRingScale)
            nativeRing(diameter: middle, progress: weeklyNudgeProgress,       colors: [.pink, Color(red: 1, green: 0.18, blue: 0.38)])
                .scaleEffect(nudgeRingScale)
            nativeRing(diameter: inner,  progress: dailyChallengeProgress,    colors: [.cyan, .mint])
                .scaleEffect(dailyRingScale)

            // Particle burst — rendered behind the emoji
            if let color = burstColor {
                RingBurst(color: color, particleScale: scale) { burstColor = nil }
                    .id(burstID)
            }

            Text(contact.emoji)
                .font(.system(size: 22 * scale))
                .scaleEffect(pulseScale)
        }
        .frame(width: outer, height: outer)
    }

    private func nativeRing(diameter: CGFloat, progress: Double, colors: [Color]) -> some View {
        let clipped   = max(min(progress, 1), 0)
        let lineWidth = 5 * scale
        return ZStack {
            Circle()
                .stroke(colors[0].opacity(0.2), lineWidth: lineWidth)
                .frame(width: diameter, height: diameter)

            Circle()
                .trim(from: 0, to: clipped)
                .stroke(
                    LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(-90))
        }
    }

    // MARK: - Ring legend

    private func ringLegend(contact: Contact) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text("\(contact.streakCount)d")
                .foregroundStyle(.orange)
            Spacer()
            Text(nudgeStatText)
                .foregroundStyle(.pink)
            Spacer()
            Text(dailyStatText)
                .foregroundStyle(.cyan)
        }
        .font(.system(size: 11 * scale, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .frame(height: 82 * scale)
    }

    // MARK: - Icon button

    private func iconButton<Content: View>(
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Button(action: action) {
            content()
                .frame(width: 32 * scale, height: 32 * scale)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Circle())
    }

    private func circleAction<Content: View>(
        label: String,
        action: @escaping () -> Void,
        @ViewBuilder icon: () -> Content
    ) -> some View {
        VStack(spacing: 4 * scale) {
            Button(action: action) {
                icon()
                    .frame(width: 44 * scale, height: 44 * scale)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())

            Text(label)
                .font(.system(size: 10 * scale, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
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

    // ring: 0 = streak (orange), 1 = nudge (pink), 2 = daily (cyan)
    private func ringCompleted(ring: Int) {
        let color: Color = ring == 0 ? .orange : ring == 1 ? .pink : .cyan
        WKInterfaceDevice.current().play(.success)

        // Pulse the completed ring
        withAnimation(.spring(response: 0.18, dampingFraction: 0.45)) {
            switch ring {
            case 0: streakRingScale = 1.2
            case 1: nudgeRingScale  = 1.2
            default: dailyRingScale = 1.2
            }
        }
        Task {
            try? await Task.sleep(for: .milliseconds(180))
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                streakRingScale = 1.0
                nudgeRingScale  = 1.0
                dailyRingScale  = 1.0
            }
        }

        // Particle burst
        burstColor = color
        burstID = UUID()
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

// MARK: - Ring burst particle effect

private struct RingBurst: View {
    let color: Color
    let particleScale: CGFloat
    let onFinish: () -> Void

    @State private var exploded = false

    private let count = 14

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let angle = (Double(i) / Double(count)) * 2 * .pi
                let dist  = 54.0 * particleScale
                Circle()
                    .fill(color.opacity(exploded ? 0 : 0.85))
                    .frame(width: 4 * particleScale, height: 4 * particleScale)
                    .offset(
                        x: exploded ? dist * cos(angle) : 0,
                        y: exploded ? dist * sin(angle) : 0
                    )
                    .scaleEffect(exploded ? 0.2 : 1.0)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.65)) { exploded = true }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(700))
            onFinish()
        }
    }
}
