import SwiftUI
import SwiftData

struct SettingsSpaceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var contacts: [Contact]
    @State private var showDeleteAlert = false
    @State private var contactToDelete: Contact?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "gearshape.fill")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Settings")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !contacts.isEmpty {
                Divider()

                ForEach(contacts) { contact in
                    HStack {
                        Text(contact.emoji)
                        Text(contact.displayName)
                            .font(.caption2)
                        Spacer()
                        Button(role: .destructive) {
                            contactToDelete = contact
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption2)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.red)
                    }
                }
            }
        }
        .alert("Remove?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                if let contact = contactToDelete {
                    modelContext.delete(contact)
                }
            }
        } message: {
            if let contact = contactToDelete {
                Text("Remove \(contact.displayName)? This can't be undone.")
            }
        }
    }
}

#Preview {
    SettingsSpaceView()
}
