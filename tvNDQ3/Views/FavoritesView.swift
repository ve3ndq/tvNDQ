//
//  FavoritesView.swift
//  tvNDQ3
//
//  Created by Nathan Dykstra on 2025-09-18.
//

import SwiftUI
import Combine

struct FavoritesView: View {
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @State private var showingPlayError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            if favoritesManager.favoriteChannels.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 80))
                        .foregroundColor(.secondary)
                    
                    Text("No Favorite Channels")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("Add channels from the Channels tab to see them here")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Favorites")
            } else {
                List {
                    ForEach(favoritesManager.favoriteChannels) { channel in
                        ChannelRowView(
                            channel: channel,
                            isFavorite: true,
                            onPlay: { playChannel(channel) },
                            onToggleFavorite: { favoritesManager.removeFromFavorites(channel) }
                        )
                    }
                }
                .navigationTitle("Favorites")
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