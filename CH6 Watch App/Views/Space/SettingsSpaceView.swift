import SwiftUI
import SwiftData

struct SettingsSpaceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var contacts: [Contact]
    @State private var contactToDelete: Contact?
    @State private var showDeleteAlert = false
    @State private var showAddPerson = false

    var body: some View {
        List {
            Section {
                Button {
                    showAddPerson = true
                } label: {
                    Label("Add Person", systemImage: "plus")
                }
            }

            if !contacts.isEmpty {
                Section("People") {
                    ForEach(contacts) { contact in
                        HStack(spacing: 8) {
                            Text(contact.emoji)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(contact.displayName)
                                    .font(.footnote)
                                Text(contact.relationship.label)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .onDelete { indexSet in
                        if let index = indexSet.first {
                            contactToDelete = contacts[index]
                            showDeleteAlert = true
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .navigationTitle("People")
        .alert("Remove?", isPresented: $showDeleteAlert, presenting: contactToDelete) { contact in
            Button("Cancel", role: .cancel) { contactToDelete = nil }
            Button("Remove", role: .destructive) {
                modelContext.delete(contact)
                contactToDelete = nil
            }
        } message: { contact in
            Text("Remove \(contact.displayName)? This can't be undone.")
        }
        .sheet(isPresented: $showAddPerson) {
            OnboardingView { showAddPerson = false }
        }
    }
}

#Preview {
    SettingsSpaceView()
}
