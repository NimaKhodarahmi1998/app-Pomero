import CloudKit
import SwiftUI

/// Read-only view of a connection's activity — the other person's moods, nudges and
/// songs. Purely informational: there are no actions here (sending lives on the watch).
struct ConnectionStatsView: View {
    let connection: CKRecord

    private let service = CloudConnectionService.shared

    @State private var isLoading = true
    @State private var currentMood: MoodType?
    @State private var moodCount = 0
    @State private var nudgeCount = 0
    @State private var songCount = 0
    @State private var activity: [ActivityItem] = []

    private var name: String {
        connection[CloudKitSchema.ConnectionKey.inviterName] as? String ?? "Connection"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                HStack(spacing: 12) {
                    StatBadge(value: moodCount, label: "Moods", systemImage: "face.smiling", tint: .yellow)
                    StatBadge(value: nudgeCount, label: "Nudges", systemImage: "hand.wave.fill", tint: .pink)
                    StatBadge(value: songCount, label: "Songs", systemImage: "music.note", tint: .mint)
                }

                if !activity.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recent activity")
                            .font(.system(.headline, design: .rounded))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(activity) { item in
                            HStack(spacing: 12) {
                                Text(item.emoji).font(.title2)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.label).font(.callout)
                                    Text(item.date, format: .relative(presentation: .named))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                } else if !isLoading {
                    ContentUnavailableView("No activity yet", systemImage: "clock",
                                           description: Text("\(name)'s moods and nudges will show up here."))
                        .padding(.top, 30)
                }
            }
            .padding()
        }
        .overlay { if isLoading { ProgressView() } }
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text(currentMood?.emoji ?? "👋")
                .font(.system(size: 56))
                .frame(width: 110, height: 110)
                .glassEffect(.regular, in: Circle())
            Text(currentMood.map { "Feeling \($0.label.lowercased())" } ?? "No mood shared yet")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func load() async {
        isLoading = true
        let myID = try? await service.currentUserRecordID().recordName
        let records = await service.fetchActivity(in: connection.recordID.zoneID)

        // Only the *other* person's actions (read-only view of them).
        let theirs = records.filter { ($0["senderID"] as? String) != myID || myID == nil }

        var items: [ActivityItem] = []
        var moods = 0, nudges = 0, songs = 0
        var newestMood: (Date, MoodType)?

        for record in theirs {
            let date = (record[CloudKitSchema.MoodKey.timestamp] as? Date) ?? .now
            switch record.recordType {
            case CloudKitSchema.RecordType.mood:
                moods += 1
                if let raw = record[CloudKitSchema.MoodKey.type] as? String, let mood = MoodType(rawValue: raw) {
                    if newestMood == nil || date > newestMood!.0 { newestMood = (date, mood) }
                    items.append(ActivityItem(id: record.recordID.recordName, date: date,
                                              emoji: mood.emoji, label: "Felt \(mood.label.lowercased())"))
                }
            case CloudKitSchema.RecordType.nudge:
                nudges += 1
                if let raw = record[CloudKitSchema.NudgeKey.type] as? String, let nudge = NudgeType(rawValue: raw) {
                    items.append(ActivityItem(id: record.recordID.recordName, date: date,
                                              emoji: nudge.emoji, label: nudge.label))
                }
            case CloudKitSchema.RecordType.song:
                songs += 1
                let title = record[CloudKitSchema.SongKey.title] as? String ?? "A song"
                let artist = record[CloudKitSchema.SongKey.artist] as? String ?? ""
                items.append(ActivityItem(id: record.recordID.recordName, date: date,
                                          emoji: "🎵", label: artist.isEmpty ? title : "\(title) — \(artist)"))
            default:
                break
            }
        }

        moodCount = moods
        nudgeCount = nudges
        songCount = songs
        currentMood = newestMood?.1
        activity = items.sorted { $0.date > $1.date }
        isLoading = false
    }
}

private struct ActivityItem: Identifiable {
    let id: String
    let date: Date
    let emoji: String
    let label: String
}

private struct StatBadge: View {
    let value: Int
    let label: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
            Text("\(value)").font(.system(.title2, design: .rounded, weight: .bold))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
