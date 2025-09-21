//
//  SettingsView.swift
//  tvNDQ3
//
//  Created by Nathan Dykstra on 2025-09-18.
//

import SwiftUI
import Combine

struct SettingsView: View {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var m3uParser = M3UParser()
    @StateObject private var epgDownloader = EPGDownloader()
    @State private var tempM3UURL: String = ""
    @State private var tempEPGURL: String = ""
    @State private var showingResetAlert = false
    @State private var showingURLError = false
    @State private var showingClearCacheAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("M3U Playlist")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("M3U URL")
                            .font(.headline)
                        
                        TextField("Enter M3U playlist URL", text: $tempM3UURL)
                            .onSubmit {
                                updateM3UURL()
                            }
                        
                        if !settingsManager.isValidURL(tempM3UURL) && !tempM3UURL.isEmpty {
                            Text("Invalid URL format")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Text("Enter the URL of your IPTV M3U playlist file")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    
                    HStack {
                        Button("Update URL") {
                            updateM3UURL()
                        }
                        .disabled(!settingsManager.isValidURL(tempM3UURL))
                        
                        Spacer()
                        
                        Button("Reset to Default") {
                            tempM3UURL = "https://iptv-org.github.io/iptv/index.m3u"
                            updateM3UURL()
                        }
                    }
                    
                    Button(action: refreshM3UNow) {
                        HStack {
                            if m3uParser.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Refreshing...")
                            } else {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh M3U Now")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(m3uParser.isLoading)
                    .buttonStyle(.plain)
                }
                
                Section(header: Text("EPG (XMLTV)")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EPG URL")
                            .font(.headline)
                        TextField("Enter EPG XMLTV URL", text: $tempEPGURL)
                            .onSubmit { updateEPGURL() }
                        if !settingsManager.isValidURL(tempEPGURL) && !tempEPGURL.isEmpty {
                            Text("Invalid URL format")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        Text("The URL to your XMLTV guide file. File is saved under app Caches/EPG.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)

                    HStack {
                        Button("Update URL") { updateEPGURL() }
                            .disabled(!settingsManager.isValidURL(tempEPGURL))
                        Spacer()
                        Button("Reset to Default") {
                            tempEPGURL = Secrets.defaultEPGURL
                            updateEPGURL()
                        }
                    }

                    Button(action: downloadEPGNow) {
                        HStack {
                            if epgDownloader.isDownloading {
                                if epgDownloader.totalBytesExpected > 0 {
                                    ProgressView(value: epgDownloader.progress)
                                        .progressViewStyle(.linear)
                                        .frame(maxWidth: 200)
                                    Text("Downloading \\(Int(epgDownloader.progress * 100))% (\(sizeString(epgDownloader.bytesReceived))/\(sizeString(epgDownloader.totalBytesExpected)))")
                                } else {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                    Text("Downloading (\(sizeString(epgDownloader.bytesReceived)))")
                                }
                            } else {
                                Image(systemName: "arrow.down.circle")
                                Text("Download EPG Now")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(epgDownloader.isDownloading)
                    .buttonStyle(.plain)
                    
                    if let saved = epgDownloader.lastSavedURL {
                        Text("Saved: \\(saved.lastPathComponent)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let updated = EPGManager.shared.lastUpdated {
                        Text("Last updated: \\((dateString(updated)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let result = epgDownloader.lastResult {
                        Text("Result: \\(result)")
                            .font(.caption)
                            .foregroundColor(result.hasPrefix("Failed") ? .red : .secondary)
                    }
                    if let err = epgDownloader.errorMessage {
                        Text("Error: \(err)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Playback")) {
                    Toggle("Use VLC URL Scheme", isOn: $settingsManager.useVLCScheme)
                }
                
                Section(header: Text("Auto Refresh")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Refresh Interval (minutes)")
                            .font(.headline)
                        
                        Picker("Refresh Interval", selection: $settingsManager.autoRefreshInterval) {
                            Text("Never").tag(0)
                            Text("12 hours").tag(720)
                            Text("24 hours").tag(1440)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        Text("How often to automatically refresh the channel list")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("EPG")) {
                    Toggle("Auto-load EPG on launch", isOn: $settingsManager.autoLoadEPGOnLaunch)
                        .help("When enabled, the app loads the most recent cached EPG file on startup if available.")
                }
                
                Section(header: Text("Data Management")) {
                    Button("Reset All Settings") {
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)
                    Button("Clear EPG Cache") {
                        showingClearCacheAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                Section(header: Text("About")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("IPTV Channel Manager")
                            .font(.headline)
                        Text("A simple IPTV channel browser for tvOS")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Text("Version 1.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                tempM3UURL = settingsManager.m3uURL
                tempEPGURL = settingsManager.epgURL
            }
        }
        .onChange(of: epgDownloader.lastSavedURL) { _, newValue in
            if let url = newValue {
                EPGManager.shared.loadFromFile(at: url)
            }
        }
        .alert("Reset Settings", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                settingsManager.resetToDefaults()
                tempM3UURL = settingsManager.m3uURL
            }
        } message: {
            Text("This will reset all settings to their default values. Are you sure?")
        }
        .alert("Clear EPG Cache", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearEPGCache()
            }
        } message: {
            Text("This will delete all cached EPG files from Caches/EPG and clear saved ETag/Last-Modified headers.")
        }
        .alert("Invalid URL", isPresented: $showingURLError) {
            Button("OK") { }
        } message: {
            Text("Please enter a valid URL format")
        }
    }
    
    private func updateM3UURL() {
        if settingsManager.isValidURL(tempM3UURL) {
            settingsManager.m3uURL = tempM3UURL
        } else {
            showingURLError = true
        }
    }
    
    private func refreshM3UNow() {
        Task {
            await m3uParser.parseM3U(from: settingsManager.m3uURL)
        }
    }
    
    private func updateEPGURL() {
        if settingsManager.isValidURL(tempEPGURL) {
            settingsManager.epgURL = tempEPGURL
        } else {
            showingURLError = true
        }
    }
    
    private func downloadEPGNow() {
        epgDownloader.download(from: settingsManager.epgURL)
    }

    private func clearEPGCache() {
        // Remove cached files
        let fm = FileManager.default
        if let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let dir = caches.appendingPathComponent("EPG", isDirectory: true)
            if fm.fileExists(atPath: dir.path) {
                try? fm.removeItem(at: dir)
            }
        }
        // Clear downloader headers
        let defaults = UserDefaults.standard
        for (k, _) in defaults.dictionaryRepresentation() {
            if k.hasPrefix("EPGCache_ETag_") || k.hasPrefix("EPGCache_LastMod_") { defaults.removeObject(forKey: k) }
        }
        // Clear EPGManager memory & persisted path
        EPGManager.shared.reload() // if a file still exists, reload; otherwise below clears
        EPGManager.shared.objectWillChange.send()
        defaults.removeObject(forKey: "LastEPGFilePath")
    }
}

// MARK: - Helpers
private func sizeString(_ bytes: Int64) -> String {
    guard bytes > 0 else { return "0 B" }
    let units = ["B","KB","MB","GB","TB"]
    var value = Double(bytes)
    var i = 0
    while value >= 1024 && i < units.count - 1 { value /= 1024; i += 1 }
    return String(format: "%.1f %@", value, units[i])
}

private func dateString(_ d: Date) -> String {
    let df = DateFormatter()
    df.dateStyle = .short
    df.timeStyle = .short
    return df.string(from: d)
}

#Preview {
    SettingsView()
}