//
//  M3UParser.swift
//  tvNDQ3
//
//  Created by Nathan Dykstra on 2025-09-18.
//

import Foundation
import Combine

class M3UParser: ObservableObject {
    @Published var channels: [Channel] = []
    @Published var channelGroups: [ChannelGroup] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func parseM3U(from urlString: String) async {
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                self.errorMessage = "Invalid URL"
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let content = String(data: data, encoding: .utf8) else {
                await MainActor.run {
                    self.errorMessage = "Failed to decode M3U content"
                    self.isLoading = false
                }
                return
            }
            
            let parsedChannels = parseM3UContent(content)
            
            await MainActor.run {
                self.channels = parsedChannels
                self.channelGroups = groupChannels(parsedChannels)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load M3U: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func parseM3UContent(_ content: String) -> [Channel] {
        let lines = content.components(separatedBy: .newlines)
        var channels: [Channel] = []
        var currentChannelInfo: (name: String?, group: String?, logo: String?) = (nil, nil, nil)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.hasPrefix("#EXTINF:") {
                // Parse channel info line
                currentChannelInfo = parseExtinf(trimmedLine)
            } else if !trimmedLine.isEmpty && !trimmedLine.hasPrefix("#") {
                // This should be a URL
                if let name = currentChannelInfo.name {
                    let channel = Channel(
                        name: name,
                        url: trimmedLine,
                        group: currentChannelInfo.group,
                        logoURL: currentChannelInfo.logo
                    )
                    channels.append(channel)
                }
                currentChannelInfo = (nil, nil, nil)
            }
        }
        
        return channels
    }
    
    private func parseExtinf(_ line: String) -> (name: String?, group: String?, logo: String?) {
        // Extract channel name (everything after the last comma)
        let components = line.components(separatedBy: ",")
        let name = components.last?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Extract group-title
        var group: String?
        if let groupRange = line.range(of: "group-title=\"") {
            let startIndex = groupRange.upperBound
            if let endRange = line[startIndex...].range(of: "\"") {
                group = String(line[startIndex..<endRange.lowerBound])
            }
        }
        
        // Extract tvg-logo
        var logo: String?
        if let logoRange = line.range(of: "tvg-logo=\"") {
            let startIndex = logoRange.upperBound
            if let endRange = line[startIndex...].range(of: "\"") {
                logo = String(line[startIndex..<endRange.lowerBound])
            }
        }
        
        return (name, group, logo)
    }
    
    private func groupChannels(_ channels: [Channel]) -> [ChannelGroup] {
        let grouped = Dictionary(grouping: channels) { channel in
            channel.group ?? "Uncategorized"
        }
        
        return grouped.map { (groupName, channels) in
            ChannelGroup(name: groupName, channels: channels.sorted { $0.name < $1.name })
        }.sorted { $0.name < $1.name }
    }
}