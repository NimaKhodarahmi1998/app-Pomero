import SwiftUI
import SwiftData
import WatchKit

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var step = 0
    @State private var name = ""
    @State private var selectedEmoji = "❤️"
    @State private var selectedColor: SpaceColor = .purple
    @State private var selectedRelationship: RelationshipType = .partner
    var onComplete: () -> Void

    private let emojiOptions = [
        "❤️", "🧡", "💛", "💚", "💙", "💜",
        "🦊", "🐻", "🐰", "🐱", "🐶", "🦋",
        "🌸", "🌻", "🔥", "⭐", "🌙", "☀️"
    ]

    var body: some View {
        TabView(selection: $step) {
            // Step 0: Welcome
            welcomeStep
                .tag(0)

            // Step 1: Name
            nameStep
                .tag(1)

            // Step 2: Relationship
            relationshipStep
                .tag(2)

            // Step 3: Emoji
            emojiStep
                .tag(3)

            // Step 4: Color
            colorStep
                .tag(4)
        }
        .tabViewStyle(.verticalPage)
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 12) {
            Text("✨")
                .font(.system(size: 44))
            Text("Welcome to CH6")
                .font(.headline)
            Text("Who matters most to you?")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Swipe down to start")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var nameStep: some View {
        VStack(spacing: 12) {
            Text("Their name")
                .font(.headline)
            TextField("Name", text: $name)
        }
        .padding(.horizontal)
    }

    private var relationshipStep: some View {
        VStack(spacing: 8) {
            Text("They are your...")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(RelationshipType.allCases) { rel in
                Button {
                    selectedRelationship = rel
                    WKInterfaceDevice.current().play(.click)
                } label: {
                    HStack {
                        Image(systemName: rel.icon)
                        Text(rel.label)
                            .font(.caption)
                        Spacer()
                        if selectedRelationship == rel {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    private var emojiStep: some View {
        let columns = [
            GridItem(.flexible()), GridItem(.flexible()),
            GridItem(.flexible()), GridItem(.flexible()),
            GridItem(.flexible()), GridItem(.flexible())
        ]
        return VStack(spacing: 8) {
            Text("Pick their emoji")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(emojiOptions, id: \.self) { emoji in
                    Button {
                        selectedEmoji = emoji
                        WKInterfaceDevice.current().play(.click)
                    } label: {
                        Text(emoji)
                            .font(.system(size: 22))
                            .padding(4)
                            .background(
                                Circle().fill(selectedEmoji == emoji ? .white.opacity(0.2) : .clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
    }

    private var colorStep: some View {
        let columns = [
            GridItem(.flexible()), GridItem(.flexible()),
            GridItem(.flexible()), GridItem(.flexible())
        ]
        return VStack(spacing: 10) {
            Text("Pick their color")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(SpaceColor.allCases) { color in
                    Button {
                        selectedColor = color
                        WKInterfaceDevice.current().play(.click)
                    } label: {
                        Circle()
                            .fill(colorValue(color))
                            .frame(width: 28, height: 28)
                            .overlay {
                                if selectedColor == color {
                                    Image(systemName: "checkmark")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            Button("Done") {
                createContact()
            }
            .disabled(name.isEmpty)
            .tint(.green)
        }
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func createContact() {
        let contact = Contact(
            name: name,
            relationship: selectedRelationship,
            emoji: selectedEmoji,
            spaceColor: selectedColor
        )
        modelContext.insert(contact)

        // Create initial challenges for this contact
        let dailyTypes: [ChallengeType] = [.checkInMood, .sendNudge]
        let weeklyTypes: [ChallengeType] = [.streakWeek, .fiveNudges]
        let monthlyTypes: [ChallengeType] = [.thirtyDayStreak]

        for type in dailyTypes + weeklyTypes + monthlyTypes {
            let challenge = Challenge(type: type, contactName: name)
            modelContext.insert(challenge)
        }

        WKInterfaceDevice.current().play(.success)
        onComplete()
    }

    private func colorValue(_ spaceColor: SpaceColor) -> Color {
        switch spaceColor {
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
    OnboardingView {}
}
