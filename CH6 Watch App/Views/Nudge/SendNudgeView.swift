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
        List {
            Section {
                ForEach(NudgeType.nudges(for: contact.relationship)) { nudge in
                    Button {
                        sendNudge(nudge)
                    } label: {
                        Label {
                            Text(nudge.label)
                        } icon: {
                            Text(nudge.emoji)
                        }
                    }
                }
            } header: {
                Text("Nudge \(contact.displayName)")
                    .font(.footnote)
                    .textCase(nil)
            }
        }
        .overlay {
            if sent, let type = sentType {
                VStack(spacing: 8) {
                    Text(type.emoji)
                        .font(.system(size: 40))
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                    Text("Sent!")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .transition(.opacity)
                .animation(.easeInOut, value: sent)
            }
        }
    }

    private func sendNudge(_ type: NudgeType) {
        let entry = NudgeEntry(type: type, isSent: true, contactName: contact.name)
        modelContext.insert(entry)
        contact.lastNudgeDate = .now
        contact.totalNudgesSent += 1
        StreakService.recordInteraction(for: contact)
        ChallengeService.recordNudgeSent(for: contact, context: modelContext)
        WKInterfaceDevice.current().play(.notification)

        sentType = type
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
