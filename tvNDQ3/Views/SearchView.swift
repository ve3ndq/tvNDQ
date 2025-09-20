//
//  SearchView.swift
//  tvNDQ3
//
//  Created by Xcode Assistant on 2025-09-20.
//

import SwiftUI
import Combine

struct SearchView: View {
    @StateObject private var m3uParser = M3UParser()
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var settingsManager = SettingsManager()

    @State private var query: String = ""
    @State private var showingPlayError = false
    @State private var errorMessage = ""

    var filteredChannels: [Channel] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        return m3uParser.channels.filter { channel in
            channel.name.localizedCaseInsensitiveContains(q) ||
            (channel.group?.localizedCaseInsensitiveContains(q) ?? false)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    TextField("Search channels or groups", text: $query)
                        .disableAutocorrection(true)
                        .submitLabel(.search)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                )

                if m3uParser.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading channels...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = m3uParser.errorMessage {
                    VStack(spacing: 12) {
                        Text("Error loading channels")
                            .font(.headline)
                        Text(error)
                            .foregroundColor(.secondary)
                        Button("Retry") { loadChannels() }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if query.isEmpty {
                    VStack(spacing: 12) {
                        Text("Start typing to search")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredChannels.isEmpty {
                    VStack(spacing: 12) {
                        Text("No results for \"\(query)\"")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredChannels) { channel in
                            ChannelRowView(
                                channel: channel,
                                isFavorite: favoritesManager.isFavorite(channel),
                                onPlay: { playChannel(channel) },
                                onToggleFavorite: { favoritesManager.toggleFavorite(channel) }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Search")
        }
        .onAppear {
            if m3uParser.channels.isEmpty && !m3uParser.isLoading {
                loadChannels()
            }
        }
        .alert("Playback Error", isPresented: $showingPlayError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func loadChannels() {
        Task {
            await m3uParser.parseM3U(from: settingsManager.m3uURL)
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
    SearchView()
}
