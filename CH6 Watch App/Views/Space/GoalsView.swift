import SwiftUI
import SwiftData

struct GoalsView: View {
    let contact: Contact

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ChallengeListView(contact: contact)
                    } label: {
                        Label {
                            Text("Challenges")
                        } icon: {
                            Image(systemName: "target")
                                .foregroundStyle(.orange)
                        }
                    }

                    NavigationLink {
                        AchievementListView(contact: contact)
                    } label: {
                        Label {
                            Text("Trophies")
                        } icon: {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                } header: {
                    Text("Goals")
                        .font(.footnote)
                        .textCase(nil)
                }
            }
            .navigationTitle("Goals")
        }
    }
}

#Preview {
    GoalsView(contact: Contact(name: "Alex", relationship: .partner))
}
