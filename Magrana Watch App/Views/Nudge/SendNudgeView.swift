import SwiftUI
import SwiftData
import WatchKit

struct SendNudgeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    var contact: Contact

    @State private var selectedIndex = 0.0
    @State private var sent = false
    @FocusState private var isFocused: Bool

    private var scale: CGFloat {
        let b = WKInterfaceDevice.current().screenBounds
        guard b.width > 0, b.height > 0 else { return 1.0 }
        return min(b.width / 198.0, b.height / 242.0)
    }

    private var nudges: [NudgeType] { NudgeType.nudges(for: contact.relationship) }
    private var accentColor: Color {
        switch currentNudge {
        case .thinkingOfYou:    return .purple
        case .checkIn:          return .blue
        case .missYou:          return .pink
        case .sendingHug:       return Color(red: 1, green: 0.6, blue: 0.4)
        case .youGotThis:       return .green
        case .loveYou:          return Color(red: 1, green: 0.18, blue: 0.38)
        case .cantWaitToSeeYou: return .pink
        case .youMakeMeSmile:   return .yellow
        case .dreamingOfYou:    return .indigo
        case .letsHangOut:      return .cyan
        case .sendingGoodVibes: return .mint
        case .howAreYou:        return Color(red: 0.4, green: 0.75, blue: 1)
        case .youreTheBest:     return Color(red: 1, green: 0.84, blue: 0)
        case .proudOfYou:       return .orange
        case .sendingLove:      return Color(red: 1, green: 0.18, blue: 0.38)
        case .alwaysHere:       return .teal
        case .greatWork:        return .green
        case .keepItUp:         return .orange
        case .letsCatchUp:      return Color(red: 0.6, green: 0.4, blue: 0.2)
        case .nailedIt:         return .blue
        case .keepGrowing:      return .mint
        case .believeInYou:     return .purple
        case .celebrate:        return .yellow
        case .support:          return .teal
        }
    }

    private var currentNudge: NudgeType {
        let count = nudges.count
        let index = Int(round(selectedIndex)) % count
        let safe = index < 0 ? index + count : index
        return nudges[safe]
    }

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [accentColor.opacity(0.35), Color.black.opacity(0.85)],
                center: .center,
                startRadius: 10,
                endRadius: 120
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.4), value: currentNudge)

            VStack(spacing: 0) {
                Text("Nudge \(contact.displayName)")
                    .font(.system(size: 11 * scale, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8 * scale)

                Spacer()

                // Emoji card
                ZStack {
                    RoundedRectangle(cornerRadius: 22 * scale)
                        .fill(.ultraThinMaterial)
                        .frame(width: 76 * scale, height: 76 * scale)
                        .shadow(color: accentColor.opacity(0.4), radius: 12)
                        .animation(.easeInOut(duration: 0.4), value: currentNudge)

                    Text(currentNudge.emoji)
                        .font(.system(size: 38 * scale))
                        .id(currentNudge)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.6).combined(with: .opacity),
                                removal: .scale(scale: 1.3).combined(with: .opacity)
                            )
                        )
                        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: currentNudge)
                }

                Spacer().frame(height: 10 * scale)

                // Label pill
                Text(currentNudge.label)
                    .font(.system(size: 13 * scale, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 12 * scale)
                    .padding(.vertical, 5 * scale)
                    .glassEffect(.regular, in: Capsule())
                    .animation(.easeInOut(duration: 0.3), value: currentNudge)

                Spacer().frame(height: 10 * scale)

                // Dot indicators
                HStack(spacing: 4) {
                    ForEach(Array(nudges.enumerated()), id: \.element.id) { _, nudge in
                        Capsule()
                            .fill(currentNudge == nudge ? accentColor : Color.white.opacity(0.2))
                            .frame(
                                width: currentNudge == nudge ? 12 * scale : 4 * scale,
                                height: 4 * scale
                            )
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentNudge)
                    }
                }

                Spacer()

                // Send button
                Button { sendNudge() } label: {
                    Text("Send Nudge")
                        .font(.system(size: 13 * scale, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8 * scale)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12 * scale))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10 * scale)
                .padding(.bottom, 6 * scale)
            }

            if sent {
                ZStack {
                    Color.black.opacity(0.3)
                    VStack(spacing: 8 * scale) {
                        Text(currentNudge.emoji)
                            .font(.system(size: 36 * scale))
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 22 * scale, weight: .medium))
                            .foregroundStyle(accentColor)
                    }
                    .padding(20 * scale)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 20 * scale))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: sent)
            }
        }
        .presentationBackground(.clear)
        .focusable()
        .focused($isFocused)
        .digitalCrownRotation(
            $selectedIndex,
            from: 0,
            through: Double(nudges.count - 1),
            by: 1,
            sensitivity: .low,
            isContinuous: true
        )
        .onAppear { isFocused = true }
    }

    private func sendNudge() {
        let entry = NudgeEntry(type: currentNudge, isSent: true, contactName: contact.name)
        modelContext.insert(entry)
        contact.lastNudgeDate = .now
        contact.totalNudgesSent += 1
        StreakService.recordInteraction(for: contact)
        ChallengeService.recordNudgeSent(for: contact, context: modelContext)
        WKInterfaceDevice.current().play(.notification)

        // Push to the other person if this space is a cross-user connection.
        if contact.connectionZoneName != nil {
            let nudge = currentNudge
            Task { await ConnectionSyncService.shared.sendNudge(nudge, for: contact) }
        }

        sent = true
        Task {
            try? await Task.sleep(for: .seconds(1))
            sent = false
            dismiss()
        }
    }
}

#Preview {
    SendNudgeView(contact: Contact(name: "Alex", relationship: .partner))
}
