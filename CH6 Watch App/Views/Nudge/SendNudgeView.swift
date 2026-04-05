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
                    Button { sendNudge(nudge) } label: {
                        HStack(spacing: 12) {
                            Text(nudge.emoji)
                                .font(.title3)
                                .frame(width: 36, height: 36)
                                .background(.white.opacity(0.08), in: Circle())

                            Text(nudge.label)
                                .font(.footnote)
                                .foregroundStyle(.primary)

                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Nudge \(contact.displayName)")
                    .font(.footnote)
                    .textCase(nil)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .overlay {
            if sent, let type = sentType {
                ZStack {
                    Color.black.opacity(0.4)

                    VStack(spacing: 8) {
                        Text(type.emoji)
                            .font(.system(size: 40))
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.tint)
                    }
                    .padding(20)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 20))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: sent)
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
