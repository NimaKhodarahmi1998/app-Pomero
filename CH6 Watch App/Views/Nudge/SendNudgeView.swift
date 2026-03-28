import SwiftUI
import SwiftData
import WatchKit

struct SendNudgeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let contact: Contact

    @State private var sent = false

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Send to \(contact.name)")
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
        .navigationTitle("Nudge")
        .overlay {
            if sent {
                sentOverlay
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
        StreakService.recordInteraction(for: contact)
        WKInterfaceDevice.current().play(.notification)

        sent = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            sent = false
            dismiss()
        }
    }

    private var sentOverlay: some View {
        VStack(spacing: 6) {
            Image(systemName: "paperplane.fill")
                .font(.system(size: 36))
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

#Preview {
    SendNudgeView(contact: Contact(name: "Alex", relationship: .partner))
}
