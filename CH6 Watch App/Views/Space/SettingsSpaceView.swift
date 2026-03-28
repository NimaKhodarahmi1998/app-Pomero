import SwiftUI

struct SettingsSpaceView: View {
    @State private var cloudKit = CloudKitService.shared
    @State private var showDisconnectAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                if let code = cloudKit.connectionCode {
                    VStack(spacing: 2) {
                        Text("Connection")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(code)
                            .font(.caption)
                            .fontDesign(.monospaced)
                    }
                }

                Button(role: .destructive) {
                    showDisconnectAlert = true
                } label: {
                    Label("Disconnect", systemImage: "link.badge.plus")
                }
                .alert("Disconnect?", isPresented: $showDisconnectAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Disconnect", role: .destructive) {
                        cloudKit.disconnect()
                    }
                } message: {
                    Text("This will end the connection. You'll need a new code to reconnect.")
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    SettingsSpaceView()
}
