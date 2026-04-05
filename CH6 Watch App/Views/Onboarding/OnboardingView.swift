import SwiftUI
import SwiftData
import WatchKit

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var path: [Int] = []
    @State private var name = ""
    @State private var selectedEmoji = "❤️"
    @State private var selectedColor: SpaceColor = .purple
    @State private var selectedRelationship: RelationshipType = .partner
    var onComplete: () -> Void

    private var scale: CGFloat {
        let b = WKInterfaceDevice.current().screenBounds
        guard b.width > 0, b.height > 0 else { return 1.0 }
        return min(b.width / 198.0, b.height / 242.0)
    }

    private let emojiOptions = [
        "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "💕", "💞", "💗", "❤️‍🔥",
        "🦊", "🐻", "🐰", "🐱", "🐶", "🦋", "🐼", "🐨", "🦁", "🐯", "🦄", "🐸",
        "🐧", "🦉", "🐺", "🦚", "🐬",
        "🌸", "🌻", "🌹", "🌺", "🍀", "🌿", "🌴", "🌵", "🍁", "🌾",
        "⭐", "🌙", "☀️", "🌈", "⚡", "🌊", "🔥", "❄️", "🌼", "☁️",
        "✨", "💎", "🎯", "🎸", "🎨", "🍓", "🫐", "🎀", "🪐", "🎵"
    ]

    var body: some View {
        NavigationStack(path: $path) {
            welcomeStep
                .navigationDestination(for: Int.self) { step in
                    switch step {
                    case 1: nameStep
                    case 2: relationshipStep
                    case 3: emojiStep
                    case 4: colorStep
                    default: EmptyView()
                    }
                }
        }
    }

    // MARK: - Welcome

    private var welcomeStep: some View {
        ZStack {
            RadialGradient(
                colors: [Color.purple.opacity(0.4), Color.black.opacity(0.9)],
                center: .center, startRadius: 10, endRadius: 130
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text("✨")
                    .font(.system(size: 40 * scale))

                Spacer().frame(height: 8 * scale)

                Text("Connesso")
                    .font(.system(size: 16 * scale, weight: .bold))

                Spacer().frame(height: 4 * scale)

                Text("Who matters most?")
                    .font(.system(size: 11 * scale))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()

                Button { advance() } label: {
                    Text("Add Person")
                        .font(.system(size: 13 * scale, weight: .semibold))
                        .foregroundStyle(.purple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8 * scale)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12 * scale))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10 * scale)
                .padding(.bottom, 6 * scale)
            }
        }
    }

    // MARK: - Name

    private var nameStep: some View {
        ZStack {
            RadialGradient(
                colors: [Color.blue.opacity(0.35), Color.black.opacity(0.9)],
                center: .center, startRadius: 10, endRadius: 130
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("Their name")
                    .font(.system(size: 11 * scale, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8 * scale)

                Spacer()

                TextField("Name or nickname", text: $name)
                    .font(.system(size: 14 * scale, weight: .medium))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10 * scale)

                Spacer()

                Button { advance() } label: {
                    Text("Next")
                        .font(.system(size: 13 * scale, weight: .semibold))
                        .foregroundStyle(Color.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8 * scale)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12 * scale))
                }
                .buttonStyle(.plain)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, 10 * scale)
                .padding(.bottom, 6 * scale)
            }
        }
    }

    // MARK: - Relationship

    private var relationshipStep: some View {
        ZStack {
            RadialGradient(
                colors: [Color.indigo.opacity(0.35), Color.black.opacity(0.9)],
                center: .center, startRadius: 10, endRadius: 130
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 7 * scale) {
                    Text("Who are they?")
                        .font(.system(size: 11 * scale, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.top, 8 * scale)

                    ForEach(RelationshipType.allCases) { rel in
                        Button {
                            selectedRelationship = rel
                            WKInterfaceDevice.current().play(.click)
                            advance()
                        } label: {
                            HStack(spacing: 10 * scale) {
                                Image(systemName: rel.icon)
                                    .font(.system(size: 13 * scale, weight: .medium))
                                    .foregroundStyle(.indigo)
                                    .frame(width: 20 * scale)
                                Text(rel.label)
                                    .font(.footnote)
                                Spacer()
                                if selectedRelationship == rel {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.tint)
                                }
                            }
                            .padding(.horizontal, 12 * scale)
                            .padding(.vertical, 9 * scale)
                            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 13 * scale))
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer().frame(height: 8 * scale)
                }
                .padding(.horizontal, 10 * scale)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Emoji

    private var emojiStep: some View {
        ZStack {
            RadialGradient(
                colors: [Color.pink.opacity(0.35), Color.black.opacity(0.9)],
                center: .center, startRadius: 10, endRadius: 130
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Text("Pick an emoji")
                        .font(.system(size: 11 * scale, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.top, 8 * scale)
                        .padding(.bottom, 8 * scale)

                    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Button {
                                selectedEmoji = emoji
                                WKInterfaceDevice.current().play(.click)
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 22 * scale))
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                                    .glassEffect(
                                        selectedEmoji == emoji ? .regular.interactive() : .regular,
                                        in: RoundedRectangle(cornerRadius: 10 * scale)
                                    )
                                    .overlay {
                                        if selectedEmoji == emoji {
                                            RoundedRectangle(cornerRadius: 10 * scale)
                                                .strokeBorder(.white.opacity(0.9), lineWidth: 1.5)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .scrollTransition(.animated.threshold(.visible(0.3))) { content, phase in
                                content
                                    .scaleEffect(1 - abs(phase.value) * 0.2)
                                    .opacity(1 - abs(phase.value) * 0.4)
                            }
                        }
                    }
                    .padding(.horizontal, 8 * scale)
                    .padding(.bottom, 8 * scale)
                }
            }
            .focusable()
            .scrollIndicators(.hidden)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button { advance() } label: {
                    Image(systemName: "checkmark").fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Color

    private var colorStep: some View {
        ZStack {
            RadialGradient(
                colors: [colorFor(selectedColor).opacity(0.4), Color.black.opacity(0.9)],
                center: .center, startRadius: 10, endRadius: 130
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.4), value: selectedColor)

            ScrollView {
                VStack(spacing: 0) {
                    Text("Pick a colour")
                        .font(.system(size: 11 * scale, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.top, 8 * scale)
                        .padding(.bottom, 8 * scale)

                    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(SpaceColor.allCases) { color in
                            Button {
                                selectedColor = color
                                WKInterfaceDevice.current().play(.click)
                            } label: {
                                Circle()
                                    .fill(colorFor(color))
                                    .aspectRatio(1, contentMode: .fit)
                                    .shadow(color: colorFor(color).opacity(0.6), radius: 5)
                                    .overlay {
                                        if selectedColor == color {
                                            Circle().strokeBorder(.white, lineWidth: 2.5)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .scrollTransition(.animated.threshold(.visible(0.3))) { content, phase in
                                content
                                    .scaleEffect(1 - abs(phase.value) * 0.2)
                                    .opacity(1 - abs(phase.value) * 0.4)
                            }
                        }
                    }
                    .padding(.horizontal, 8 * scale)
                    .padding(.bottom, 8 * scale)
                }
            }
            .focusable()
            .scrollIndicators(.hidden)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button { createContact() } label: {
                    Image(systemName: "checkmark").fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Actions

    private func advance() {
        path.append(path.count + 1)
    }

    private func createContact() {
        let contact = Contact(
            name: name,
            relationship: selectedRelationship,
            emoji: selectedEmoji,
            spaceColor: selectedColor
        )
        modelContext.insert(contact)

        let challengeTypes: [ChallengeType] = [
            .checkInMood, .sendNudge,
            .streakWeek, .fiveNudges, .allMoods,
            .thirtyDayStreak, .hundredNudges, .moodJourney
        ]
        for type in challengeTypes {
            modelContext.insert(Challenge(type: type, contactName: name))
        }

        AchievementService.createAll(for: name, context: modelContext)
        WKInterfaceDevice.current().play(.success)
        onComplete()
    }
}

#Preview {
    OnboardingView {}
}
