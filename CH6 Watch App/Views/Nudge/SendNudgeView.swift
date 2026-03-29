import SwiftUI
import SwiftData
import WatchKit

struct SendNudgeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    var contact: Contact

    @State private var sent = false
    @State private var sentType: NudgeType?

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Nudge \(contact.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(NudgeType.allCases) { nudge in
                    Button {
                        sendNudge(nudge)
                    } label: {
                        HStack {
                            Text(nudge.emoji)
                                .font(.title3)
                            Text(nudge.label)
                                .font(.caption)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(.horizontal)
        }
        .overlay {
            if sent, let type = sentType {
                VStack(spacing: 6) {
                    Text(type.emoji)
                        .font(.system(size: 40))
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                    Text("Sent!")
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .transition(.opacity)
                .animation(.easeInOut, value: sent)
            }
        }
    }

    private func sendNudge(_ type: NudgeType) {
        let entry = NudgeEntry(
            type: type,
            isSent: true,
            contactName: contact.name
        )
        modelContext.insert(entry)
        contact.lastNudgeDate = .now
        contact.totalNudgesSent += 1
        StreakService.recordInteraction(for: contact)
        ChallengeService.recordNudgeSent(for: contact, context: modelContext)
        WKInterfaceDevice.current().play(.notification)

        sentType = type
        sent = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            sent = false
            dismiss()
        }
    }
}

#Preview {
    SendNudgeView(contact: Contact(name: "Alex", relationship: .partner))
}
