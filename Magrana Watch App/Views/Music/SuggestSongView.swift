import SwiftUI
import SwiftData
import MusicKit
import WatchKit

struct SuggestSongView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let contact: Contact

    @State private var searchText = ""
    @State private var results: [Song] = []
    @State private var isSearching = false
    @State private var authStatus: MusicAuthorization.Status = .notDetermined
    @State private var suggested = false
    @State private var suggestedSong: Song?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            switch authStatus {
            case .authorized:
                searchBody
            case .denied, .restricted:
                deniedBody
            default:
                requestBody
            }
        }
        .task { authStatus = await MusicAuthorization.request() }
    }

    // MARK: - Authorization states

    private var requestBody: some View {
        VStack(spacing: 10) {
            Image(systemName: "music.note")
                .font(.system(size: 30))
                .foregroundStyle(.pink)
            Text("Music Access")
                .font(.headline)
            Text("Allow access to search Apple Music")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var deniedBody: some View {
        VStack(spacing: 8) {
            Image(systemName: "music.note.list")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("Music access denied.\nEnable it in Settings.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Search UI

    private var searchBody: some View {
        List {
            Section {
                HStack(spacing: 6) {
                    TextField("Song or artist…", text: $searchText)
                        .font(.footnote)
                        .submitLabel(.search)
                        .onSubmit { Task { await search() } }

                    if isSearching {
                        ProgressView()
                            .frame(width: 14, height: 14)
                    } else {
                        Button { Task { await search() } } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.footnote)
                                .foregroundStyle(.pink)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                Text("Suggest to \(contact.displayName)")
                    .font(.footnote)
                    .textCase(nil)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }

            if !results.isEmpty {
                Section {
                    ForEach(results) { song in
                        Button { suggest(song) } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(song.title)
                                    .font(.footnote)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                Text(song.artistName)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .overlay {
            if suggested {
                confirmationOverlay
            }
        }
    }

    private var confirmationOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
            VStack(spacing: 8) {
                Text("🎵")
                    .font(.system(size: 36))
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.pink)
            }
            .padding(20)
            .glassEffect(in: RoundedRectangle(cornerRadius: 20))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: suggested)
    }

    // MARK: - Logic

    private func search() async {
        let term = searchText.trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty else { return }
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }
        do {
            var request = MusicCatalogSearchRequest(term: term, types: [Song.self])
            request.limit = 8
            let response = try await request.response()
            results = Array(response.songs)
            if results.isEmpty {
                errorMessage = "No results found."
            }
        } catch {
            errorMessage = "Search failed. Check your connection and Apple Music subscription."
        }
    }

    private func suggest(_ song: Song) {
        let suggestion = SongSuggestion(
            songTitle: song.title,
            artistName: song.artistName,
            albumTitle: song.albumTitle ?? "",
            appleMusicURL: song.url?.absoluteString,
            contactName: contact.name
        )
        modelContext.insert(suggestion)
        WKInterfaceDevice.current().play(.notification)
        suggestedSong = song
        suggested = true
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            suggested = false
            dismiss()
        }
    }
}

#Preview {
    SuggestSongView(contact: Contact(name: "Alex", relationship: .partner))
}
