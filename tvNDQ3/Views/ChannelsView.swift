//
//  ChannelsView.swift
//  tvNDQ3
//
//  Created by Nathan Dykstra on 2025-09-18.
//

import SwiftUI
import Combine

struct ChannelsView: View {
    @StateObject private var m3uParser = M3UParser()
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var settingsManager = SettingsManager()
    
    @State private var showingPlayError = false
    @State private var errorMessage = ""
    @State private var selectedGroup: ChannelGroup?
    
    var body: some View {
        NavigationView {
            VStack {
                if m3uParser.isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(2)
                        Text("Loading channels...")
                            .font(.title2)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = m3uParser.errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("Error Loading Channels")
                            .font(.title)
                        
                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            loadChannels()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if m3uParser.channelGroups.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tv")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Channels Available")
                            .font(.title)
                            .foregroundColor(.secondary)
                        
                        Text("Configure your M3U URL in Settings to load channels")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Load Channels") {
                            loadChannels()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    channelGroupsView
                }
            }
            .navigationTitle("Channels")
            // Toolbar intentionally left empty to hide top-right button
        }
        .onAppear {
            if m3uParser.channelGroups.isEmpty {
                loadChannels()
            }
        }
        .onExitCommand {
            if selectedGroup != nil {
                selectedGroup = nil
            }
        }
        .alert("Playback Error", isPresented: $showingPlayError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var channelGroupsView: some View {
        if let selectedGroup = selectedGroup {
            return AnyView(channelListView(for: selectedGroup))
        } else {
            return AnyView(groupsListView)
        }
    }
    
    private var groupsListView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 20)
            ], spacing: 20) {
                ForEach(m3uParser.channelGroups) { group in
                    GroupCardView(group: group) {
                        selectedGroup = group
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
        }
    }
    
    private func channelListView(for group: ChannelGroup) -> some View {
        VStack {
            HStack {
                Spacer()
                
                Text(group.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(group.channels.count) channels")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            List {
                ForEach(group.channels) { channel in
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

struct GroupCardView: View {
    let group: ChannelGroup
    let onTap: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "folder")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("\(group.channels.count)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                }
                
                Text(group.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Text("channels")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 3)
                )
        )
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .focused($isFocused)
    }
}

#Preview {
    ChannelsView()
}