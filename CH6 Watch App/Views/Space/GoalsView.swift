import SwiftUI
import SwiftData
import WatchKit

struct GoalsView: View {
    let contact: Contact

    private var scale: CGFloat {
        let b = WKInterfaceDevice.current().screenBounds
        guard b.width > 0, b.height > 0 else { return 1.0 }
        return min(b.width / 198.0, b.height / 242.0)
    }

    private var accentColor: Color { colorFor(contact.spaceColor) }

    var body: some View {
        NavigationStack {
            ZStack {
                RadialGradient(
                    colors: [accentColor.opacity(0.3), Color.black.opacity(0.85)],
                    center: .center,
                    startRadius: 10,
                    endRadius: 120
                )
                .ignoresSafeArea()

                VStack(spacing: 10 * scale) {
                    NavigationLink {
                        ChallengeListView(contact: contact)
                    } label: {
                        HStack(spacing: 12 * scale) {
                            Image(systemName: "target")
                                .font(.system(size: 16 * scale, weight: .medium))
                                .foregroundStyle(.orange)
                                .frame(width: 24 * scale)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Challenges")
                                    .font(.footnote.weight(.semibold))
                                Text("Daily, weekly & custom")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 14 * scale)
                        .padding(.vertical, 13 * scale)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16 * scale))
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        AchievementListView(contact: contact)
                    } label: {
                        HStack(spacing: 12 * scale) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 16 * scale, weight: .medium))
                                .foregroundStyle(.yellow)
                                .frame(width: 24 * scale)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Trophies")
                                    .font(.footnote.weight(.semibold))
                                Text("Unlock achievements")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 14 * scale)
                        .padding(.vertical, 13 * scale)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16 * scale))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10 * scale)
            }
            .navigationTitle("Goals")
        }
        .presentationBackground(.clear)
    }
}

#Preview {
    GoalsView(contact: Contact(name: "Alex", relationship: .partner))
}
