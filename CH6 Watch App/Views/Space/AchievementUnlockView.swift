import SwiftUI

struct AchievementUnlockView: View {
    let type: AchievementType
    let onDismiss: () -> Void

    @State private var cardScale = 0.5
    @State private var opacity = 0.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 6) {
                Text(type.emoji)
                    .font(.system(size: 40))
                    .scaleEffect(cardScale)

                Text(type.title)
                    .font(.system(size: 14, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Achievement Unlocked!")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.yellow)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .glassEffect(in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 12)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(duration: 0.4)) {
                cardScale = 1.0
                opacity = 1.0
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.easeOut(duration: 0.3)) { opacity = 0 }
            try? await Task.sleep(for: .milliseconds(300))
            onDismiss()
        }
    }
}

#Preview {
    AchievementUnlockView(type: .firstSpark) {}
}
