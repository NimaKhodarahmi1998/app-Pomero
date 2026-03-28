import SwiftUI
import SwiftData
import WatchKit

struct MoodSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let contact: Contact

    @State private var saved = false
    @State private var selectedMood: MoodType?

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("How do you feel about \(contact.name)?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(MoodType.allCases) { mood in
                        MoodButton(mood: mood, isSelected: selectedMood == mood) {
                            selectedMood = mood
                            saveMood(mood)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .overlay {
            if saved, let mood = selectedMood {
                savedOverlay(mood: mood)
            }
        }
    }

    private func saveMood(_ mood: MoodType) {
        let entry = MoodEntry(type: mood, contact: contact)
        modelContext.insert(entry)
        contact.currentMood = mood
        StreakService.recordInteraction(for: contact)
        WKInterfaceDevice.current().play(.success)

        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            saved = false
            dismiss()
        }
    }

    @ViewBuilder
    private func savedOverlay(mood: MoodType) -> some View {
        VStack(spacing: 6) {
            Text(mood.emoji)
                .font(.system(size: 48))
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .transition(.opacity)
        .animation(.easeInOut, value: saved)
    }
}

#Preview {
    MoodSelectionView(contact: Contact(name: "Alex", relationship: .partner))
}
