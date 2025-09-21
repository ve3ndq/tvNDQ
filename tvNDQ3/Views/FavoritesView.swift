import SwiftUI
import Combine

struct FavoritesView: View {
	@ObservedObject private var favoritesManager = FavoritesManager.shared
	@ObservedObject private var epgManager = EPGManager.shared
	@State private var showingPlayError = false
	@State private var errorMessage = ""
    
	private func normalizeChannelName(_ name: String) -> String {
		var s = name.lowercased()
		if let idx = s.firstIndex(of: ":") {
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
    
	private func currentTitle(for channelName: String, at date: Date = Date()) -> String? {
		// exact
		if let list = epgManager.programsByChannelName[channelName] {
			return list.first { date >= $0.start && date < $0.end }?.title
		}
		// normalized
		let target = normalizeChannelName(channelName)
		if let key = epgManager.programsByChannelName.keys.first(where: { normalizeChannelName($0) == target }),
		   let list = epgManager.programsByChannelName[key] {
			return list.first { date >= $0.start && date < $0.end }?.title
		}
		// contains
		if let key = epgManager.programsByChannelName.keys.first(where: {
			let norm = normalizeChannelName($0)
			return norm.contains(target) || target.contains(norm)
		}), let list = epgManager.programsByChannelName[key] {
			return list.first { date >= $0.start && date < $0.end }?.title
		}
		return nil
	}
    
	var body: some View {
		NavigationView {
			if favoritesManager.favoriteChannels.isEmpty {
				VStack(spacing: 16) {
					Image(systemName: "heart")
						.font(.system(size: 60))
						.foregroundColor(.secondary)
					Text("No favorites yet")
						.foregroundColor(.secondary)
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity)
			} else {
				List {
					ForEach(favoritesManager.favoriteChannels) { channel in
						let subtitle = currentTitle(for: channel.name)
						ChannelRowView(
							channel: channel,
							isFavorite: favoritesManager.isFavorite(channel),
							onPlay: { playChannel(channel) },
							onToggleFavorite: { favoritesManager.toggleFavorite(channel) }
						)
					}
				}
				.navigationTitle("Favorites")
				// Refresh the list whenever EPG data refreshes
				.id(epgManager.lastUpdated)
			}
		}
		.alert("Playback Error", isPresented: $showingPlayError) {
			Button("OK") { }
		} message: {
			Text(errorMessage)
		}
	}
    
	private func playChannel(_ channel: Channel) {
		VLCLauncher.shared.playChannel(channel) { success in
			if !success {
				DispatchQueue.main.async {
					errorMessage = "Could not play channel. Make sure VLC is installed or try a different player."
					showingPlayError = true
				}
			}
		}
	}
}

#Preview {
	FavoritesView()
}

