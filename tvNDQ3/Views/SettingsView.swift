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
    @State private var tempM3UURL: String = ""
    @State private var showingResetAlert = false
    @State private var showingURLError = false
    
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
                
                Section(header: Text("Data Management")) {
                    Button("Reset All Settings") {
                        showingResetAlert = true
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
}

#Preview {
    SettingsView()
}