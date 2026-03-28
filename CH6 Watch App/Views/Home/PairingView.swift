import SwiftUI
import WatchKit

struct PairingView: View {
    @State private var cloudKit = CloudKitService.shared
    @State private var showCreate = false
    @State private var showJoin = false

    var body: some View {
        VStack(spacing: 12) {
            Text("Connect with someone")
                .font(.headline)
                .multilineTextAlignment(.center)

            Button("Create Code") {
                showCreate = true
            }

            Button("Enter Code") {
                showJoin = true
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateConnectionView()
        }
        .sheet(isPresented: $showJoin) {
            JoinConnectionView()
        }
    }
}

// MARK: - Create Connection (Person A)

struct CreateConnectionView: View {
    @State private var cloudKit = CloudKitService.shared
    @State private var name = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if let code = cloudKit.connectionCode {
                    // Code created — share it
                    QRCodeGenerator.generate(from: "ch6://connect/\(code)", size: 80)

                    Text(code)
                        .font(.title3)
                        .fontWeight(.bold)
                        .fontDesign(.monospaced)

                    Text("Share this code with the other person")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("They entered it — Connect!") {
                        WKInterfaceDevice.current().play(.success)
                        cloudKit.isConnected = true
                        UserDefaults.standard.set(true, forKey: "isConnected")
                        dismiss()
                    }
                    .tint(.green)

                } else {
                    TextField("Your name", text: $name)
                        .textContentType(.name)

                    Button("Create") {
                        Task {
                            await cloudKit.createConnection(myName: name)
                        }
                    }
                    .disabled(name.isEmpty)
                }

                if let error = cloudKit.error {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Join Connection (Person B)

struct JoinConnectionView: View {
    @State private var cloudKit = CloudKitService.shared
    @State private var name = ""
    @State private var code = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                TextField("Your name", text: $name)
                    .textContentType(.name)

                TextField("6-digit code", text: $code)

                Button("Connect") {
                    Task {
                        await cloudKit.joinConnection(code: code, myName: name)
                        if cloudKit.isConnected {
                            dismiss()
                        }
                    }
                }
                .disabled(name.isEmpty || code.count < 6)

                if let error = cloudKit.error {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    PairingView()
}
