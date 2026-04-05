import SwiftUI
import SwiftData
import WatchKit

struct ChallengeListView: View {
    let contact: Contact
    @Query private var allChallenges: [Challenge]
    @Environment(\.modelContext) private var modelContext

    private var challenges: [Challenge] {
        allChallenges.filter { $0.contactName == contact.name }
    }

    private var dailyChallenges: [Challenge]   { challenges.filter { $0.type.period == .daily } }
    private var weeklyChallenges: [Challenge]  { challenges.filter { $0.type.period == .weekly } }
    private var monthlyChallenges: [Challenge] { challenges.filter { $0.type.period == .monthly } }

    var body: some View {
        List {
            if !dailyChallenges.isEmpty {
                Section("Daily") {
                    ForEach(dailyChallenges)   { ChallengeRow(challenge: $0) }
                }
            }
            if !weeklyChallenges.isEmpty {
                Section("Weekly") {
                    ForEach(weeklyChallenges)  { ChallengeRow(challenge: $0) }
                }
            }
            if !monthlyChallenges.isEmpty {
                Section("Monthly") {
                    ForEach(monthlyChallenges) { ChallengeRow(challenge: $0) }
                }
            }
            if challenges.isEmpty {
                Text("No challenges yet")
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .navigationTitle("Challenges")
        .onAppear {
            ChallengeService.resetChallengesIfNeeded(for: contact.name, context: modelContext)
        }
    }
}

struct ChallengeRow: View {
    let challenge: Challenge

    private var scale: CGFloat {
        let b = WKInterfaceDevice.current().screenBounds
        guard b.width > 0, b.height > 0 else { return 1.0 }
        return min(b.width / 198.0, b.height / 242.0)
    }

    var body: some View {
        HStack(spacing: 10) {
            Gauge(value: challenge.progressFraction) {
                EmptyView()
            } currentValueLabel: {
                if challenge.isCompleted {
                    Image(systemName: "checkmark").foregroundStyle(.green)
                } else {
                    Text(challenge.type.emoji)
                }
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(challenge.isCompleted ? .green : .orange)
            .frame(width: 30, height: 30)
            .scaleEffect(scale)
            .frame(width: 30 * scale, height: 30 * scale)

            VStack(alignment: .leading, spacing: 2) {
                Text(challenge.type.title)
                    .font(.footnote)
                    .foregroundStyle(challenge.isCompleted ? .green : .primary)
                Text("\(challenge.progress)/\(challenge.type.target)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ChallengeListView(contact: Contact(name: "Alex", relationship: .partner))
}
