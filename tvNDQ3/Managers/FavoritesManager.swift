//
//  FavoritesManager.swift
//  tvNDQ3
//
//  Created by Nathan Dykstra on 2025-09-18.
//

import Foundation
import Combine

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    @Published var favoriteChannels: [Channel] = []
    
    private let favoritesKey = "FavoriteChannels"
    
    private init() {
        loadFavorites()
    }
    
    func addToFavorites(_ channel: Channel) {
        if !favoriteChannels.contains(where: { $0.url == channel.url }) {
            favoriteChannels.append(channel)
            saveFavorites()
        }
    }
    
    func removeFromFavorites(_ channel: Channel) {
        favoriteChannels.removeAll { $0.url == channel.url }
        saveFavorites()
    }
    
    func isFavorite(_ channel: Channel) -> Bool {
        return favoriteChannels.contains { $0.url == channel.url }
    }
    
    func toggleFavorite(_ channel: Channel) {
        if isFavorite(channel) {
            removeFromFavorites(channel)
        } else {
            addToFavorites(channel)
        }
    }
    
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favoriteChannels) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        }
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode([Channel].self, from: data) {
            favoriteChannels = decoded
        }
    }
}