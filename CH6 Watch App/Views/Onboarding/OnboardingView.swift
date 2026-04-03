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

    private let emojiOptions = [
        // Hearts & love
        "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "💕", "💞", "💗", "❤️‍🔥",
        // Animals
        "🦊", "🐻", "🐰", "🐱", "🐶", "🦋", "🐼", "🐨", "🦁", "🐯", "🦄", "🐸",
        "🐧", "🦉", "🐺", "🦚", "🐬",
        // Nature
        "🌸", "🌻", "🌹", "🌺", "🍀", "🌿", "🌴", "🌵", "🍁", "🌾",
        // Sky & elements
        "⭐", "🌙", "☀️", "🌈", "⚡", "🌊", "🔥", "❄️", "🌼", "☁️",
        // Fun
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

    // MARK: - Steps

    private var welcomeStep: some View {
        ScrollView {
            VStack() {
                Text("✨")
                    .font(.largeTitle)
                Text("Connesso")
                    .font(.headline)
                Text("Who matters most to you?")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Add Person") { advance() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private var nameStep: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Their name/nickname")
                    .font(.headline)
                TextField("Name", text: $name)
                Button("Next") { advance() }
                    .disabled(name.isEmpty)
                    .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
        }
        //.navigationTitle("Name")
    }

    private var relationshipStep: some View {
        List {
            Section("Who are they to you?") {
                ForEach(RelationshipType.allCases) { rel in
                    Button {
                        selectedRelationship = rel
                        WKInterfaceDevice.current().play(.click)
                        advance()
                    } label: {
                        HStack {
                            Label(rel.label, systemImage: rel.icon)
                            Spacer()
                            if selectedRelationship == rel {
                                Image(systemName: "checkmark").foregroundStyle(.tint)
                            }
                        }
                    }
                }
            }
        }
    }

    private var emojiStep: some View {
        ScrollView {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(emojiOptions, id: \.self) { emoji in
                    Button {
                        selectedEmoji = emoji
                        WKInterfaceDevice.current().play(.click)
                    } label: {
                        Circle()
                            .fill(Color.white.opacity(0.13))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                Text(emoji).font(.title2)
                            }
                            .overlay {
                                if selectedEmoji == emoji {
                                    Circle().strokeBorder(.white, lineWidth: 2.5)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .scrollTransition(.animated.threshold(.visible(0.3))) { content, phase in
                        content
                            .scaleEffect(1 - abs(phase.value) * 0.3)
                            .opacity(1 - abs(phase.value) * 0.5)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button { advance() } label: {
                    Image(systemName: "checkmark").fontWeight(.semibold)
                }
            }
        }
    }

    private var colorStep: some View {
        ScrollView {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(SpaceColor.allCases) { color in
                    Button {
                        selectedColor = color
                        WKInterfaceDevice.current().play(.click)
                    } label: {
                        Circle()
                            .fill(colorValue(color))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                if selectedColor == color {
                                    Circle().strokeBorder(.white, lineWidth: 2.5)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .scrollTransition(.animated.threshold(.visible(0.3))) { content, phase in
                        content
                            .scaleEffect(1 - abs(phase.value) * 0.3)
                            .opacity(1 - abs(phase.value) * 0.5)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            .padding(.bottom, 8)
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
            let challenge = Challenge(type: type, contactName: name)
            modelContext.insert(challenge)
        }

        AchievementService.createAll(for: name, context: modelContext)

        WKInterfaceDevice.current().play(.success)
        onComplete()
    }

    private func colorValue(_ spaceColor: SpaceColor) -> Color {
        colorFor(spaceColor)
    }
}

#Preview {
    OnboardingView {}
}
