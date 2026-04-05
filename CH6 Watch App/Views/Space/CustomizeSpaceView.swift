import SwiftUI
import SwiftData
import WatchKit

struct CustomizeSpaceView: View {
    var contact: Contact

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    RelationshipPickerView(contact: contact)
                } label: {
                    Label("Relationship", systemImage: contact.relationship.icon)
                }

                NavigationLink {
                    EmojiPickerView(contact: contact)
                } label: {
                    Label {
                        Text("Emoji")
                    } icon: {
                        Text(contact.emoji)
                    }
                }

                NavigationLink {
                    ColorPickerView(contact: contact)
                } label: {
                    Label {
                        Text("Background")
                    } icon: {
                        Circle()
                            .fill(colorFor(contact.spaceColor))
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .navigationTitle("Style")
        }
    }
}

// MARK: - Relationship

private struct RelationshipPickerView: View {
    var contact: Contact

    var body: some View {
        List {
            ForEach(RelationshipType.allCases) { rel in
                Button {
                    contact.relationship = rel
                    WKInterfaceDevice.current().play(.click)
                } label: {
                    HStack {
                        Label(rel.label, systemImage: rel.icon)
                        Spacer()
                        if contact.relationship == rel {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
        }
        .navigationTitle("Relationship")
    }
}

// MARK: - Emoji

private struct EmojiPickerView: View {
    var contact: Contact

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
        ScrollView {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(emojiOptions, id: \.self) { emoji in
                    Button {
                        contact.emoji = emoji
                        WKInterfaceDevice.current().play(.click)
                    } label: {
                        Text(emoji)
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                if contact.emoji == emoji {
                                    Circle().strokeBorder(.white, lineWidth: 2.5)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: Circle())
                    .scrollTransition(.animated.threshold(.visible(0.3))) { content, phase in
                        content
                            .scaleEffect(1 - abs(phase.value) * 0.3)
                            .opacity(1 - abs(phase.value) * 0.5)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .focusable()
        .navigationTitle("Emoji")
    }
}

// MARK: - Color

private struct ColorPickerView: View {
    var contact: Contact

    var body: some View {
        ScrollView {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(SpaceColor.allCases) { color in
                    Button {
                        contact.spaceColor = color
                        WKInterfaceDevice.current().play(.click)
                    } label: {
                        Circle()
                            .fill(colorFor(color))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                if contact.spaceColor == color {
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
            .padding(.vertical, 4)
        }
        .focusable()
        .navigationTitle("Background")
    }
}

// MARK: - Shared color helper

func colorFor(_ spaceColor: SpaceColor) -> Color {
    switch spaceColor {
    case .red:      return .red
    case .orange:   return .orange
    case .yellow:   return .yellow
    case .green:    return .green
    case .mint:     return .mint
    case .teal:     return .teal
    case .cyan:     return .cyan
    case .blue:     return .blue
    case .indigo:   return .indigo
    case .purple:   return .purple
    case .pink:     return .pink
    case .rose:     return Color(red: 1, green: 0.18, blue: 0.38)
    case .coral:    return Color(red: 1, green: 0.40, blue: 0.30)
    case .lime:     return Color(red: 0.55, green: 0.90, blue: 0.15)
    case .sky:      return Color(red: 0.40, green: 0.75, blue: 1)
    case .violet:   return Color(red: 0.62, green: 0.32, blue: 1)
    case .brown:    return .brown
    case .gray:     return Color(white: 0.5)
    case .gold:     return Color(red: 1, green: 0.84, blue: 0)
    case .peach:    return Color(red: 1, green: 0.72, blue: 0.58)
    case .lavender: return Color(red: 0.73, green: 0.61, blue: 0.92)
    case .magenta:  return Color(red: 0.84, green: 0.11, blue: 0.65)
    case .emerald:  return Color(red: 0.05, green: 0.60, blue: 0.35)
    case .crimson:  return Color(red: 0.70, green: 0.05, blue: 0.18)
    case .amber:    return Color(red: 1, green: 0.63, blue: 0.05)
    case .navy:     return Color(red: 0.07, green: 0.10, blue: 0.40)
    case .olive:    return Color(red: 0.40, green: 0.45, blue: 0.10)
    case .tan:      return Color(red: 0.82, green: 0.71, blue: 0.55)
    }
}

#Preview {
    CustomizeSpaceView(contact: Contact(name: "Alex", relationship: .partner))
}
