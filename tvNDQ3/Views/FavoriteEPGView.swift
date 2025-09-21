import SwiftUI
import Combine

struct FavoriteEPGView: View {
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @ObservedObject private var epgManager = EPGManager.shared
    @State private var showingPlayError = false
    @State private var playErrorMessage = ""

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
                                    Button {
                                        playChannel(ch)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "play.fill")
                                            Text("Play")
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                        .font(.caption2)
                                    }
                                    .buttonStyle(.plain)
                            }
                            if let cur = row.current {
                                    Text("Now: \(cur.title.isEmpty ? "(no title)" : cur.title) — \(timeString(cur.start))–\(timeString(cur.end))")
                                        .font(.caption)
                            } else {
                                    Text("Now: (none)").font(.caption)
                            }
                            if let next = row.next {
                                    Text("Next: \(next.title.isEmpty ? "(no title)" : next.title) — \(timeString(next.start))–\(timeString(next.end))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                            }
                        }
                            .padding(.vertical, 4)
                    }
                }

                
            }
            .navigationTitle("Favorite EPG")
        }
        .alert("Playback Error", isPresented: $showingPlayError) {
            Button("OK") {}
        } message: {
            Text(playErrorMessage)
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
    
    private func playChannel(_ channel: Channel) {
        VLCLauncher.shared.playChannel(channel) { success in
            if !success {
                DispatchQueue.main.async {
                    playErrorMessage = "Could not play channel. Ensure VLC is installed or try a different player."
                    showingPlayError = true
                }
            }
        }
    }
}

#Preview { FavoriteEPGView() }
