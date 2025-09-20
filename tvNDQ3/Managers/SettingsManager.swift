//
//  SettingsManager.swift
//  tvNDQ3
//
//  Created by Nathan Dykstra on 2025-09-18.
//

import Foundation
import Combine

class SettingsManager: ObservableObject {
    @Published var m3uURL: String {
        didSet {
            UserDefaults.standard.set(m3uURL, forKey: m3uURLKey)
        }
    }
    
    @Published var epgURL: String {
        didSet {
            UserDefaults.standard.set(epgURL, forKey: epgURLKey)
        }
    }
    
    @Published var autoRefreshInterval: Int {
        didSet {
            UserDefaults.standard.set(autoRefreshInterval, forKey: autoRefreshKey)
        }
    }
    
    @Published var useVLCScheme: Bool {
        didSet {
            UserDefaults.standard.set(useVLCScheme, forKey: vlcSchemeKey)
        }
    }
    
    private let m3uURLKey = "M3UURL"
    private let epgURLKey = "EPGURL"
    private let autoRefreshKey = "AutoRefreshInterval"
    private let vlcSchemeKey = "UseVLCScheme"
    
    init() {
        self.m3uURL = UserDefaults.standard.string(forKey: m3uURLKey) ?? Secrets.defaultM3UURL
        self.epgURL = UserDefaults.standard.string(forKey: epgURLKey) ?? Secrets.defaultEPGURL
        self.autoRefreshInterval = UserDefaults.standard.object(forKey: autoRefreshKey) as? Int ?? 1440 // 24 hours
        self.useVLCScheme = UserDefaults.standard.object(forKey: vlcSchemeKey) as? Bool ?? true
    }
    
    func resetToDefaults() {
        m3uURL = Secrets.defaultM3UURL
        epgURL = Secrets.defaultEPGURL
        autoRefreshInterval = 1440
        useVLCScheme = true
    }
    
    func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme != nil && url.host != nil
    }
}