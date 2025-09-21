import SwiftUI
import Combine

struct FavoriteEPGView: View {
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @ObservedObject private var epgManager = EPGManager.shared

    struct Row: Identifiable {
        let id = UUID()
        let channel: Channel
        let matchKey: String?
        let matchType: String
        let current: EPGProgram?
        let next: EPGProgram?
    }

    private func buildRow(for channel: Channel) -> Row {
        // Try exact
        if let list = epgManager.programsByChannelName[channel.name] {
            let current = list.first { Date() >= $0.start && Date() < $0.end }
            let next = list.first { $0.start >= Date() }
            return Row(channel: channel, matchKey: channel.name, matchType: "exact", current: current, next: next)
        }
        // Try normalized match (using the same logic as EPGManager)
        let target = normalizeChannelName(channel.name)
        if let key = epgManager.programsByChannelName.keys.first(where: { normalizeChannelName($0) == target }) {
            if let list = epgManager.programsByChannelName[key] {
                let current = list.first { Date() >= $0.start && Date() < $0.end }
                let next = list.first { $0.start >= Date() }
                return Row(channel: channel, matchKey: key, matchType: "normalized", current: current, next: next)
            }
        }
        // Contains
        if let key = epgManager.programsByChannelName.keys.first(where: {
            let norm = normalizeChannelName($0)
            return norm.contains(target) || target.contains(norm)
        }) {
            if let list = epgManager.programsByChannelName[key] {
                let current = list.first { Date() >= $0.start && Date() < $0.end }
                let next = list.first { $0.start >= Date() }
                return Row(channel: channel, matchKey: key, matchType: "contains", current: current, next: next)
            }
        }
        return Row(channel: channel, matchKey: nil, matchType: "no-match", current: nil, next: nil)
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Favorites: \(favoritesManager.favoriteChannels.count)")) {
                    ForEach(favoritesManager.favoriteChannels) { ch in
                        let row = buildRow(for: ch)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text(ch.name).font(.headline)
                                Spacer()
                                Text(row.matchType.uppercased())
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(color(for: row.matchType))
                                    )
                            }
                            if let key = row.matchKey {
                                Text("EPG key: \(key)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("EPG key: (none)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if let cur = row.current {
                                Text("Now: \(cur.title.isEmpty ? "(no title)" : cur.title) — \(timeString(cur.start))–\(timeString(cur.end))")
                                    .font(.body)
                            } else {
                                Text("Now: (none)").font(.body)
                            }
                            if let next = row.next {
                                Text("Next: \(next.title.isEmpty ? "(no title)" : next.title) — \(timeString(next.start))–\(timeString(next.end))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }

                Section(header: Text("Stats")) {
                    HStack {
                        Text("Channels in EPG").foregroundColor(.secondary)
                        Spacer()
                        Text("\(epgManager.channelCount)")
                    }
                    HStack {
                        Text("Programs in EPG").foregroundColor(.secondary)
                        Spacer()
                        Text("\(epgManager.programCount)")
                    }
                    if let url = epgManager.lastFileURL {
                        HStack { Text("Last file").foregroundColor(.secondary); Spacer(); Text(url.lastPathComponent) }
                    }
                }
            }
            .navigationTitle("Favorite EPG")
        }
    }

    private func timeString(_ d: Date) -> String {
        let df = DateFormatter(); df.dateStyle = .none; df.timeStyle = .short
        return df.string(from: d)
    }

    private func normalizeChannelName(_ name: String) -> String {
        var s = name.lowercased()
        if let idx = s.firstIndex(of: ":"), s.startIndex == s.startIndex {
            let prefix = s[..<idx]
            if prefix.count <= 3 { s = String(s[s.index(after: idx)...]) }
        }
        s = s.replacingOccurrences(of: "\\s*\\([^\\)]*\\)", with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: "\\s*\\[[^\\]]*\\]", with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: "-", with: " ")
        s = s.replacingOccurrences(of: "_", with: " ")
        s = s.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        return s
    }

    private func color(for type: String) -> Color {
        switch type {
        case "exact": return Color.green.opacity(0.3)
        case "normalized": return Color.blue.opacity(0.3)
        case "contains": return Color.orange.opacity(0.3)
        default: return Color.red.opacity(0.3)
        }
    }
}

#Preview { FavoriteEPGView() }
