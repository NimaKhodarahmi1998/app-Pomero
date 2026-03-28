import SwiftUI
import SwiftData
import WatchKit

struct PersonSpaceView: View {
    @Environment(\.modelContext) private var modelContext
    let contact: Contact

    @State private var showMoodPicker = false
    @State private var showNudgePicker = false
    @State private var showCustomize = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // Avatar emoji
                    Text(contact.emoji)
                        .font(.system(size: 44))

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
                            Text("\(contact.streakCount) day streak")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }

                    // Contact's current mood
                    if let mood = contact.currentMood {
                        VStack(spacing: 2) {
                            Text(mood.emoji)
                                .font(.system(size: 36))
                            Text("Feeling \(mood.label.lowercased())")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.vertical, 4)
                    } else {
                        Text("No mood set")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.vertical, 4)
                    }

                    // Action buttons
                    HStack(spacing: 12) {
                        Button {
                            showMoodPicker = true
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "face.smiling")
                                    .font(.title3)
                                Text("Mood")
                                    .font(.system(size: 9))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))

                        Button {
                            showNudgePicker = true
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "hand.tap")
                                    .font(.title3)
                                Text("Nudge")
                                    .font(.system(size: 9))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal)
            }
            .background(spaceGradient)
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
        }
    }

    private var spaceGradient: some View {
        LinearGradient(
            colors: [spaceUIColor.opacity(0.8), spaceUIColor.opacity(0.3), .black],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
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
