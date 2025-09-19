//
//  ContentView.swift
//  tvNDQ3
//
//  Created by Nathan Dykstra on 2025-09-18.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            FavoritesView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favorites")
                }
            
            ChannelsView()
                .tabItem {
                    Image(systemName: "tv")
                    Text("Channels")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
    }
}

#Preview {
    ContentView()
}
