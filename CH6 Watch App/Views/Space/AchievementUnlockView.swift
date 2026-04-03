import SwiftUI

struct AchievementUnlockView: View {
    let type: AchievementType
    let onDismiss: () -> Void

    @State private var scale = 0.3
    @State private var opacity = 0.0

    var body: some View {
        VStack(spacing: 10) {
            Text(type.emoji)
                .font(.system(size: 48))
                .scaleEffect(scale)

            Text(type.title)
                .font(.headline)

            Text("Achievement unlocked!")
                .font(.caption)
                .foregroundStyle(.yellow)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring) {
                scale = 1.0
                opacity = 1.0
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 0.3)) { opacity = 0 }
            try? await Task.sleep(for: .milliseconds(300))
            onDismiss()
        }
    }
}

#Preview {
    AchievementUnlockView(type: .firstSpark) {}
}
