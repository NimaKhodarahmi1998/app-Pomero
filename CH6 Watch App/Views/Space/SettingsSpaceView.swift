import SwiftUI
import SwiftData
import WatchKit

struct SettingsSpaceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var contacts: [Contact]
    @State private var contactToDelete: Contact?
    @State private var showDeleteAlert = false
    @State private var showAddPerson = false

    private var scale: CGFloat {
        let b = WKInterfaceDevice.current().screenBounds
        guard b.width > 0, b.height > 0 else { return 1.0 }
        return min(b.width / 198.0, b.height / 242.0)
    }

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color.indigo.opacity(0.3), Color.black.opacity(0.9)],
                center: .center, startRadius: 10, endRadius: 130
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 8 * scale) {
                    // Add Person button
                    Button { showAddPerson = true } label: {
                        HStack(spacing: 10 * scale) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16 * scale, weight: .medium))
                                .foregroundStyle(.indigo)
                                .frame(width: 24 * scale)
                            Text("Add Person")
                                .font(.footnote.weight(.semibold))
                            Spacer()
                        }
                        .padding(.horizontal, 14 * scale)
                        .padding(.vertical, 12 * scale)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16 * scale))
                    }
                    .buttonStyle(.plain)

                    if !contacts.isEmpty {
                        // People list
                        VStack(spacing: 6 * scale) {
                            Text("People")
                                .font(.system(size: 10 * scale, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 4 * scale)
                                .padding(.top, 4 * scale)

                            ForEach(contacts) { contact in
                                HStack(spacing: 10 * scale) {
                                    Text(contact.emoji)
                                        .font(.system(size: 20 * scale))
                                        .frame(width: 28 * scale, height: 28 * scale)
                                        .glassEffect(.regular, in: Circle())

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(contact.displayName)
                                            .font(.footnote.weight(.medium))
                                        Text(contact.relationship.label)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Button {
                                        contactToDelete = contact
                                        showDeleteAlert = true
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 14 * scale))
                                            .foregroundStyle(.red.opacity(0.8))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 12 * scale)
                                .padding(.vertical, 10 * scale)
                                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14 * scale))
                            }
                        }
                    }

                    Spacer().frame(height: 8 * scale)
                }
                .padding(.horizontal, 10 * scale)
                .padding(.top, 8 * scale)
            }
            .scrollIndicators(.hidden)
        }
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
