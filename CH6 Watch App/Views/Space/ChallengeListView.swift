import SwiftUI
import SwiftData
import WatchKit

struct ChallengeListView: View {
    let contact: Contact
    @Query private var allChallenges: [Challenge]
    @Query private var allCustom: [CustomChallenge]
    @Environment(\.modelContext) private var modelContext

    private var challenges: [Challenge] {
        allChallenges.filter { $0.contactName == contact.name }
    }
    private var customChallenges: [CustomChallenge] {
        allCustom.filter { $0.contactName == contact.name }
    }

    private var dailyChallenges: [Challenge]   { challenges.filter { $0.type.period == .daily } }
    private var weeklyChallenges: [Challenge]  { challenges.filter { $0.type.period == .weekly } }
    private var monthlyChallenges: [Challenge] { challenges.filter { $0.type.period == .monthly } }

    var body: some View {
        List {
            if !dailyChallenges.isEmpty {
                Section("Daily") {
                    ForEach(dailyChallenges) { ChallengeRow(challenge: $0) }
                }
            }
            if !weeklyChallenges.isEmpty {
                Section("Weekly") {
                    ForEach(weeklyChallenges) { ChallengeRow(challenge: $0) }
                }
            }
            if !monthlyChallenges.isEmpty {
                Section("Monthly") {
                    ForEach(monthlyChallenges) { ChallengeRow(challenge: $0) }
                }
            }

            Section("Custom") {
                ForEach(customChallenges) { custom in
                    CustomChallengeRow(challenge: custom) {
                        toggleCustom(custom)
                    }
                }
                .onDelete { indexSet in
                    indexSet.map { customChallenges[$0] }.forEach { modelContext.delete($0) }
                }

                NavigationLink {
                    AddCustomChallengeView(contactName: contact.name)
                } label: {
                    Label("Add Challenge", systemImage: "plus.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(.cyan)
                }
            }

            if challenges.isEmpty && customChallenges.isEmpty {
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

    private func toggleCustom(_ challenge: CustomChallenge) {
        challenge.isCompleted.toggle()
        challenge.completedAt = challenge.isCompleted ? .now : nil
        WKInterfaceDevice.current().play(.click)
    }
}

// MARK: - Custom challenge row

struct CustomChallengeRow: View {
    let challenge: CustomChallenge
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: challenge.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(challenge.isCompleted ? .green : .secondary)

                Text(challenge.title)
                    .font(.footnote)
                    .foregroundStyle(challenge.isCompleted ? .secondary : .primary)
                    .strikethrough(challenge.isCompleted)
                    .lineLimit(2)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add custom challenge

struct AddCustomChallengeView: View {
    let contactName: String
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""

    var body: some View {
        VStack(spacing: 12) {
            TextField("Challenge name…", text: $title)
                .font(.footnote)
                .submitLabel(.done)
                .onSubmit { save() }

            Button("Add") { save() }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding()
        .navigationTitle("New Challenge")
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        modelContext.insert(CustomChallenge(title: trimmed, contactName: contactName))
        dismiss()
    }
}

// MARK: - Standard challenge row

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
