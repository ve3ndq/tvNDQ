//
//  EPGManager.swift
//  tvNDQ3
//
//  Holds parsed EPG data and exposes lookup helpers.
//

import Foundation
import Combine

final class EPGManager: ObservableObject {
    static let shared = EPGManager()
    
    @Published private(set) var programsByChannelName: [String: [EPGProgram]] = [:]
    @Published private(set) var programsByChannelId: [String: [EPGProgram]] = [:]
    @Published private(set) var channelsById: [String: String] = [:] // id -> display-name
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastFileURL: URL?
    @Published private(set) var lastFileSizeBytes: Int64 = 0
    @Published private(set) var channelCount: Int = 0
    @Published private(set) var programCount: Int = 0
    
    private let parser = EPGParser()
    private init() {}
    
    func loadFromFile(at url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let result = parser.parse(data: data)
            var byName: [String: [EPGProgram]] = [:]
            var byId: [String: [EPGProgram]] = [:]
            for p in result.programs {
                byId[p.channelId, default: []].append(p)
                let name = result.channels[p.channelId] ?? p.channelId
                byName[name, default: []].append(p)
            }
            for key in byName.keys { byName[key]?.sort { $0.start < $1.start } }
            for key in byId.keys { byId[key]?.sort { $0.start < $1.start } }
            DispatchQueue.main.async {
                self.channelsById = result.channels
                self.programsByChannelName = byName
                self.programsByChannelId = byId
                self.channelCount = result.channels.count
                self.programCount = result.programs.count
                self.lastUpdated = Date()
                self.lastFileURL = url
                self.lastFileSizeBytes = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.int64Value ?? 0
                self.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func reload() {
        guard let url = lastFileURL else { return }
        loadFromFile(at: url)
    }
    
    func currentProgram(for channelName: String, at date: Date = Date()) -> EPGProgram? {
        guard let list = programsByChannelName[channelName] else { return nil }
        // binary search could be added; linear is acceptable to start
        return list.first { date >= $0.start && date < $0.end }
    }

    func programs(forDisplayName name: String) -> [EPGProgram] {
        // Find the channel id for this display-name
        if let id = channelsById.first(where: { $0.value == name })?.key {
            return programsByChannelId[id] ?? []
        }
        // attempt case-insensitive fallback
        if let id = channelsById.first(where: { $0.value.compare(name, options: .caseInsensitive) == .orderedSame })?.key {
            return programsByChannelId[id] ?? []
        }
        return []
    }
    
    func channelId(forDisplayName name: String) -> String? {
        if let id = channelsById.first(where: { $0.value == name })?.key { return id }
        return channelsById.first(where: { $0.value.compare(name, options: .caseInsensitive) == .orderedSame })?.key
    }
}
