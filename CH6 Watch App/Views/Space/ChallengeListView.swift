import SwiftUI
import SwiftData

struct ChallengeListView: View {
    let contact: Contact
    @Query private var allChallenges: [Challenge]
    @Environment(\.modelContext) private var modelContext

    private var challenges: [Challenge] {
        allChallenges.filter { $0.contactName == contact.name }
    }

    private var dailyChallenges: [Challenge] {
        challenges.filter { $0.type.period == .daily }
    }

    private var weeklyChallenges: [Challenge] {
        challenges.filter { $0.type.period == .weekly }
    }

    private var monthlyChallenges: [Challenge] {
        challenges.filter { $0.type.period == .monthly }
    }

    var body: some View {
        List {
            if !dailyChallenges.isEmpty {
                Section("Daily") {
                    ForEach(dailyChallenges) { challenge in
                        ChallengeRow(challenge: challenge)
                    }
                }
            }

            if !weeklyChallenges.isEmpty {
                Section("Weekly") {
                    ForEach(weeklyChallenges) { challenge in
                        ChallengeRow(challenge: challenge)
                    }
                }
            }

            if !monthlyChallenges.isEmpty {
                Section("Monthly") {
                    ForEach(monthlyChallenges) { challenge in
                        ChallengeRow(challenge: challenge)
                    }
                }
            }

            if challenges.isEmpty {
                Text("No challenges yet")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Challenges")
        .onAppear {
            ChallengeService.resetChallengesIfNeeded(for: contact.name, context: modelContext)
        }
    }
}

struct ChallengeRow: View {
    let challenge: Challenge

    var body: some View {
        HStack(spacing: 10) {
            Gauge(value: challenge.progressFraction) {
                EmptyView()
            } currentValueLabel: {
                if challenge.isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                } else {
                    Text(challenge.type.emoji)
                }
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(challenge.isCompleted ? .green : .orange)
            .frame(width: 30, height: 30)

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
