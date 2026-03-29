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
        ScrollView {
            VStack(spacing: 14) {
                Text("Challenges")
                    .font(.headline)

                if !dailyChallenges.isEmpty {
                    challengeSection("Daily", icon: "sun.max.fill", challenges: dailyChallenges)
                }

                if !weeklyChallenges.isEmpty {
                    challengeSection("Weekly", icon: "calendar", challenges: weeklyChallenges)
                }

                if !monthlyChallenges.isEmpty {
                    challengeSection("Monthly", icon: "moon.stars.fill", challenges: monthlyChallenges)
                }

                if challenges.isEmpty {
                    Text("No challenges yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            ChallengeService.resetDailyChallenges(for: contact.name, context: modelContext)
        }
    }

    @ViewBuilder
    private func challengeSection(_ title: String, icon: String, challenges: [Challenge]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            ForEach(challenges) { challenge in
                ChallengeRow(challenge: challenge)
            }
        }
    }
}

struct ChallengeRow: View {
    let challenge: Challenge

    var body: some View {
        HStack(spacing: 8) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 3)
                    .frame(width: 28, height: 28)
                Circle()
                    .trim(from: 0, to: challenge.progressFraction)
                    .stroke(
                        challenge.isCompleted ? Color.green : Color.orange,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 28, height: 28)
                    .rotationEffect(.degrees(-90))

                if challenge.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.green)
                } else {
                    Text(challenge.type.emoji)
                        .font(.system(size: 10))
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(challenge.type.title)
                    .font(.caption2)
                    .foregroundStyle(challenge.isCompleted ? .green : .white)
                Text("\(challenge.progress)/\(challenge.type.target)")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ChallengeListView(contact: Contact(name: "Alex", relationship: .partner))
}
