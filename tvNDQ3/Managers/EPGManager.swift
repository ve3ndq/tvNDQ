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
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var errorMessage: String?
    
    private let parser = EPGParser()
    private init() {}
    
    func loadFromFile(at url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let result = parser.parse(data: data)
            // Heuristic: build reverse map from channel display-name to id
            var byName: [String: [EPGProgram]] = [:]
            for p in result.programs {
                let name = result.channels[p.channelId] ?? p.channelId
                byName[name, default: []].append(p)
            }
            for key in byName.keys {
                byName[key]?.sort { $0.start < $1.start }
            }
            DispatchQueue.main.async {
                self.programsByChannelName = byName
                self.lastUpdated = Date()
                self.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func currentProgram(for channelName: String, at date: Date = Date()) -> EPGProgram? {
        guard let list = programsByChannelName[channelName] else { return nil }
        // binary search could be added; linear is acceptable to start
        return list.first { date >= $0.start && date < $0.end }
    }
}
