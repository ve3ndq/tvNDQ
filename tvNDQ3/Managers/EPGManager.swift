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
    private let lastEPGFilePathKey = "LastEPGFilePath"
    private let parsedCacheFileName = "parsed_epg_cache.json"
    private let downloader = EPGDownloader()
    private var cancellables: Set<AnyCancellable> = []
    private init() {
        // Try restoring a cached EPG on background queue to avoid blocking UI
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard SettingsManager().autoLoadEPGOnLaunch else { return }
            if !self!.loadParsedCache() {
                self?.restoreCachedEPG()
            }
        }

        // Observe downloader completion and load file
        downloader.$lastSavedURL
            .receive(on: DispatchQueue.main)
            .sink { [weak self] url in
                guard let url = url else { return }
                self?.loadFromFile(at: url)
            }
            .store(in: &cancellables)
    }
    
    func loadFromFile(at url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Stream-parse from file to reduce memory footprint
            let result = self.parser.parse(fileURL: url)
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
                // Persist last file path for next launch
                UserDefaults.standard.set(url.path, forKey: self.lastEPGFilePathKey)
                // Save parsed cache for faster warm start
                self.saveParsedCache()
                // After loading, check if stale (based on lastUpdated)
                self.checkAndRefreshIfStale(referenceDate: self.lastUpdated)
            }
        }
    }
    
    func reload() {
        guard let url = lastFileURL else { return }
        loadFromFile(at: url)
    }
    
    func currentProgram(for channelName: String, at date: Date = Date()) -> EPGProgram? {
        // Exact match first
        if let list = programsByChannelName[channelName] {
            return list.first { date >= $0.start && date < $0.end }
        }
        // Fallback: normalized name match against EPG display-names
        let target = normalizeChannelName(channelName)
        if let key = programsByChannelName.keys.first(where: { normalizeChannelName($0) == target }) {
            if let list = programsByChannelName[key] {
                return list.first { date >= $0.start && date < $0.end }
            }
        }
        // Secondary fallback: contains check (handles cases like "CA: CBC TORONTO" vs "CBC Toronto (CBLT-DT)")
        if let key = programsByChannelName.keys.first(where: {
            let norm = normalizeChannelName($0)
            return norm.contains(target) || target.contains(norm)
        }) {
            if let list = programsByChannelName[key] {
                return list.first { date >= $0.start && date < $0.end }
            }
        }
        return nil
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

    // MARK: - Name Normalization
    private func normalizeChannelName(_ name: String) -> String {
        var s = name.lowercased()
        // Remove country prefixes like "ca:" or "us:" if present at the very start
        if let idx = s.firstIndex(of: ":"), s.startIndex == s.startIndex {
            let prefix = s[..<idx]
            if prefix.count <= 3 { s = String(s[s.index(after: idx)...]) }
        }
        // Remove content in parentheses/brackets e.g., (CBLT-DT), [HD]
        s = s.replacingOccurrences(of: "\\s*\\([^\\)]*\\)", with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: "\\s*\\[[^\\]]*\\]", with: "", options: .regularExpression)
        // Remove common separators
        s = s.replacingOccurrences(of: "-", with: " ")
        s = s.replacingOccurrences(of: "_", with: " ")
        // Keep letters and numbers only
        s = s.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        return s
    }

    // MARK: - Cache Restore
    private func restoreCachedEPG() {
        // 1) Try the last used file path in UserDefaults
        if let path = UserDefaults.standard.string(forKey: lastEPGFilePathKey) {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                self.loadFromFile(at: url)
                return
            }
        }
        // 2) Fallback: load the most recent file from the Caches/EPG directory
        if let dir = storageDirectory(),
           let url = mostRecentFile(in: dir) {
            self.loadFromFile(at: url)
        }
    }

    private func storageDirectory() -> URL? {
        guard let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let dir = base.appendingPathComponent("EPG", isDirectory: true)
        // Create directory if missing
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func mostRecentFile(in directory: URL) -> URL? {
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) else { return nil }
        return files.max { lhs, rhs in
            let l = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let r = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return l < r
        }
    }

    // MARK: - Parsed Cache
    private func cacheURL() -> URL? {
        guard let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let dir = base.appendingPathComponent("EPG", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(parsedCacheFileName)
    }

    private struct ParsedSnapshot: Codable {
        let channelsById: [String:String]
        let programs: [EPGProgram]
        let lastUpdated: Date
        let lastFileURLPath: String?
        let lastFileSizeBytes: Int64
    }

    private func saveParsedCache() {
        guard let url = cacheURL() else { return }
        // Flatten programs into array; rebuild indices on load
        let allPrograms = programsByChannelId.values.flatMap { $0 }
        let snapshot = ParsedSnapshot(channelsById: channelsById, programs: allPrograms, lastUpdated: lastUpdated ?? Date(), lastFileURLPath: lastFileURL?.path, lastFileSizeBytes: lastFileSizeBytes)
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: url, options: .atomic)
        } catch {
            // best-effort cache; ignore errors
        }
    }

    private func loadParsedCache() -> Bool {
        guard let url = cacheURL(), let data = try? Data(contentsOf: url) else { return false }
        do {
            let snapshot = try JSONDecoder().decode(ParsedSnapshot.self, from: data)
            var byName: [String:[EPGProgram]] = [:]
            var byId: [String:[EPGProgram]] = [:]
            for p in snapshot.programs {
                byId[p.channelId, default: []].append(p)
                let name = snapshot.channelsById[p.channelId] ?? p.channelId
                byName[name, default: []].append(p)
            }
            for key in byName.keys { byName[key]?.sort { $0.start < $1.start } }
            for key in byId.keys { byId[key]?.sort { $0.start < $1.start } }
            DispatchQueue.main.async {
                self.channelsById = snapshot.channelsById
                self.programsByChannelName = byName
                self.programsByChannelId = byId
                self.channelCount = snapshot.channelsById.count
                self.programCount = snapshot.programs.count
                self.lastUpdated = snapshot.lastUpdated
                if let path = snapshot.lastFileURLPath { self.lastFileURL = URL(fileURLWithPath: path) }
                self.lastFileSizeBytes = snapshot.lastFileSizeBytes
                self.errorMessage = nil
                // Check staleness against cached lastUpdated
                self.checkAndRefreshIfStale(referenceDate: snapshot.lastUpdated)
            }
            return true
        } catch {
            return false
        }
    }

    // MARK: - Auto Refresh
    private func checkAndRefreshIfStale(referenceDate: Date?) {
        guard !downloader.isDownloading else { return }
        guard let ref = referenceDate else { return }
        let minutes = SettingsManager().autoRefreshInterval
        let threshold: TimeInterval = Double(minutes) * 60
        if Date().timeIntervalSince(ref) >= threshold {
            refreshEPG()
        }
    }

    private func refreshEPG() {
        let settings = SettingsManager()
        let urlString = settings.epgURL
        guard settings.isValidURL(urlString) else { return }
        downloader.download(from: urlString)
    }
}
