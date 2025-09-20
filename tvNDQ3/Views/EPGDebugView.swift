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
