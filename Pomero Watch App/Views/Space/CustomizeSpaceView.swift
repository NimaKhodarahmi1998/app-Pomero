import SwiftUI
import SwiftData
import WatchKit

struct CustomizeSpaceView: View {
    var contact: Contact

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {

                    NavigationLink {
                        RelationshipPickerView(contact: contact)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: contact.relationship.icon)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            Text("Relationship")
                                .font(.footnote.weight(.medium))
                            Spacer()
                            Text(contact.relationship.label)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        EmojiPickerView(contact: contact)
                    } label: {
                        HStack(spacing: 12) {
                            Text(contact.emoji)
                                .font(.system(size: 18))
                                .frame(width: 24)
                            Text("Emoji")
                                .font(.footnote.weight(.medium))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        ColorPickerView(contact: contact)
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(colorFor(contact.spaceColor))
                                .frame(width: 18, height: 18)
                                .shadow(color: colorFor(contact.spaceColor).opacity(0.7), radius: 5)
                                .frame(width: 24)
                            Text("Background")
                                .font(.footnote.weight(.medium))
                            Spacer()
                            Text(contact.spaceColor.rawValue.capitalized)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)

                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Style")
        }
        .presentationBackground(.ultraThinMaterial)
    }
}

// MARK: - Relationship picker

private struct RelationshipPickerView: View {
    var contact: Contact

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(RelationshipType.allCases) { rel in
                    Button {
                        contact.relationship = rel
                        WKInterfaceDevice.current().play(.click)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: rel.icon)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.blue)
                                .frame(width: 20)
                            Text(rel.label)
                                .font(.footnote)
                            Spacer()
                            if contact.relationship == rel {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.tint)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Relationship")
    }
}

// MARK: - Emoji picker

private struct EmojiPickerView: View {
    var contact: Contact

    private let emojiOptions = [
        "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "💕", "💞", "💗", "❤️‍🔥",
        "🦊", "🐻", "🐰", "🐱", "🐶", "🦋", "🐼", "🐨", "🦁", "🐯", "🦄", "🐸",
        "🐧", "🦉", "🐺", "🦚", "🐬",
        "🌸", "🌻", "🌹", "🌺", "🍀", "🌿", "🌴", "🌵", "🍁", "🌾",
        "⭐", "🌙", "☀️", "🌈", "⚡", "🌊", "🔥", "❄️", "🌼", "☁️",
        "✨", "💎", "🎯", "🎸", "🎨", "🍓", "🫐", "🎀", "🪐", "🎵"
    ]

    var body: some View {
        ScrollView {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(emojiOptions, id: \.self) { emoji in
                    Button {
                        contact.emoji = emoji
                        WKInterfaceDevice.current().play(.click)
                    } label: {
                        Text(emoji)
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .glassEffect(
                                contact.emoji == emoji ? .regular.interactive() : .regular,
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay {
                                if contact.emoji == emoji {
                                    RoundedRectangle(cornerRadius: 10)
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
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .focusable()
        .scrollContentBackground(.hidden)
        .navigationTitle("Emoji")
    }
}

// MARK: - Color picker

private struct ColorPickerView: View {
    var contact: Contact

    var body: some View {
        ScrollView {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(SpaceColor.allCases) { color in
                    Button {
                        contact.spaceColor = color
                        WKInterfaceDevice.current().play(.click)
                    } label: {
                        Circle()
                            .fill(colorFor(color))
                            .aspectRatio(1, contentMode: .fit)
                            .shadow(color: colorFor(color).opacity(0.6), radius: 5)
                            .overlay {
                                if contact.spaceColor == color {
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
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .focusable()
        .scrollContentBackground(.hidden)
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
