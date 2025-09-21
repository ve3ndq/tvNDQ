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
            FavoriteEPGView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("Favorite EPG")
                }            
                
                FavoritesView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favorites")
                }

            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            
            EPGDebugView()
                .tabItem {
                    Image(systemName: "ladybug")
                    Text("EPG Debug")
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
