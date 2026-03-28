import SwiftUI
import WatchKit

struct MoodButton: View {
    let mood: MoodType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            WKInterfaceDevice.current().play(.click)
            action()
        }) {
            VStack(spacing: 2) {
                Text(mood.emoji)
                    .font(.system(size: 28))
                Text(mood.label)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.3) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        MoodButton(mood: .happy, isSelected: false) {}
        MoodButton(mood: .sad, isSelected: true) {}
    }
}
