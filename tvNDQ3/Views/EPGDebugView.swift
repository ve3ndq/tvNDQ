//
//  EPGDebugView.swift
//  tvNDQ3
//
//  Shows airings for a specific channel display-name to verify EPG parsing.
//

import SwiftUI

struct EPGDebugView: View {
    @ObservedObject private var epgManager = EPGManager.shared
    private let targetDisplayName = "CA: CBC TORONTO"
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                Text("EPG Debug — \(targetDisplayName)")
                    .font(.title2)
                    .bold()
                HStack(spacing: 12) {
                    Button(action: epgManager.reload) {
                        Label("Reparse Last File", systemImage: "arrow.clockwise")
                    }
                    .disabled(epgManager.lastFileURL == nil)
                    
                    Button(action: {}) {
                        Label("Saved in Caches/EPG", systemImage: "folder")
                    }
                }
                .buttonStyle(.bordered)
                
                epgInfo
                if epgManager.programsByChannelId.isEmpty && epgManager.channelsById.isEmpty {
                    Text("No EPG loaded. Download in Settings → EPG (XMLTV).")
                        .foregroundColor(.secondary)
                } else {
                    let shows = epgManager.programs(forDisplayName: targetDisplayName)
                    if shows.isEmpty {
                        Text("No airings found for \(targetDisplayName)")
                            .foregroundColor(.secondary)
                    } else {
                        List(shows) { p in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(p.title.isEmpty ? "(no title)" : p.title)
                                        .font(.body)
                                    Text("\(format(p.start)) — \(format(p.end))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                Spacer()
            }
            .padding()
            .navigationTitle("EPG Debug")
        }
    }
    
    private var epgInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("File info")
                .font(.headline)
            HStack {
                Text("Path:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(epgManager.lastFileURL?.lastPathComponent ?? "(none)")
                    .font(.caption)
            }
            HStack {
                Text("Size:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(sizeString(epgManager.lastFileSizeBytes))
                    .font(.caption)
            }
            HStack {
                Text("Channels:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\\(epgManager.channelCount)")
                    .font(.caption)
            }
            HStack {
                Text("Programs:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\\(epgManager.programCount)")
                    .font(.caption)
            }
            if let updated = epgManager.lastUpdated {
                HStack {
                    Text("Last updated:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(dateString(updated))
                        .font(.caption)
                }
            }
            if let id = epgManager.channelId(forDisplayName: targetDisplayName) {
                HStack {
                    Text("Channel id:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(id)
                        .font(.caption)
                }
            }
            if let err = epgManager.errorMessage {
                Text("Error: \\(err)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private func sizeString(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 B" }
        let units = ["B","KB","MB","GB","TB"]
        var value = Double(bytes)
        var i = 0
        while value > 1024 && i < units.count - 1 { value /= 1024; i += 1 }
        return String(format: "%.1f %@", value, units[i])
    }
    
    private func dateString(_ d: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df.string(from: d)
    }
    
    private func openDocumentsFolder() {
        // tvOS cannot open Finder, but leaving as placeholder for future tooling/logging.
    }
    
    private func format(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .short
        return df.string(from: date)
    }
}

#Preview {
    EPGDebugView()
}
