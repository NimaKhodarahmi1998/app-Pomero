import SwiftUI
import SwiftData

struct MainTabView: View {
    @Query private var contacts: [Contact]
    @State private var showOnboarding = false
    @State private var showAddPerson = false

    var body: some View {
        if contacts.isEmpty {
            // First launch — onboarding
            OnboardingView {
                showOnboarding = false
            }
        } else {
            TabView {
                ForEach(contacts) { contact in
                    PersonSpaceView(contact: contact)
                }

                // Last page: add person + settings
                addAndSettingsPage
            }
        }
    }

    private var addAndSettingsPage: some View {
        ScrollView {
            VStack(spacing: 16) {
                Button {
                    showAddPerson = true
                } label: {
                    Label("Add Person", systemImage: "plus.circle.fill")
                }
                .tint(.green)

                Divider()

                SettingsSpaceView()
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showAddPerson) {
            OnboardingView {
                showAddPerson = false
            }
        }
    }
}

#Preview {
    MainTabView()
}
