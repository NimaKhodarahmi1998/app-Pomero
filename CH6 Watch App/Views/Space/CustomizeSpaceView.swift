import SwiftUI
import SwiftData
import WatchKit

struct CustomizeSpaceView: View {
    @Environment(\.dismiss) private var dismiss
    var contact: Contact

    @State private var nickname: String = ""
    @State private var selectedEmoji: String = ""

    private let emojiOptions = [
        "❤️", "🧡", "💛", "💚", "💙", "💜",
        "🦊", "🐻", "🐰", "🐱", "🐶", "🦋",
        "🌸", "🌻", "🔥", "⭐", "🌙", "☀️",
        "🍀", "🎯", "💎", "🎸", "🎨", "✨"
    ]

    let colorColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    let emojiColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Nickname
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nickname")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    TextField(contact.name, text: $nickname)
                        .onAppear { nickname = contact.nickname ?? "" }
                        .onChange(of: nickname) {
                            contact.nickname = nickname.isEmpty ? nil : nickname
                        }
                }

                // Emoji picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Emoji")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: emojiColumns, spacing: 6) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Button {
                                contact.emoji = emoji
                                WKInterfaceDevice.current().play(.click)
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 20))
                                    .padding(4)
                                    .background(
                                        Circle()
                                            .fill(contact.emoji == emoji ? .white.opacity(0.2) : .clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Color picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Color")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: colorColumns, spacing: 8) {
                        ForEach(SpaceColor.allCases) { color in
                            Button {
                                contact.spaceColor = color
                                WKInterfaceDevice.current().play(.click)
                            } label: {
                                Circle()
                                    .fill(colorFor(color))
                                    .frame(width: 28, height: 28)
                                    .overlay {
                                        if contact.spaceColor == color {
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
                }

                Button("Done") {
                    dismiss()
                }
                .padding(.top, 6)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Customize")
    }

    private func colorFor(_ spaceColor: SpaceColor) -> Color {
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
    CustomizeSpaceView(contact: Contact(name: "Alex", relationship: .partner))
}
