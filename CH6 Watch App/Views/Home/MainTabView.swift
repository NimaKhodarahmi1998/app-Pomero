import SwiftUI
import SwiftData

struct MainTabView: View {
    @Query private var contacts: [Contact]

    var body: some View {
        if contacts.isEmpty {
            OnboardingView { }
        } else {
            TabView {
                ForEach(contacts) { contact in
                    PersonSpaceView(contactName: contact.name)
                }
                SettingsSpaceView()
            }
            .id(contacts.count)
        }
    }
}

#Preview {
    MainTabView()
}
