import SwiftUI
import SwiftData

struct MainTabView: View {
    @Query private var contacts: [Contact]

    var body: some View {
        TabView {
            ForEach(contacts) { contact in
                PersonSpaceView(contact: contact)
            }

            SettingsSpaceView()
        }
    }
}

#Preview {
    MainTabView()
}
