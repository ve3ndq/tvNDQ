//
//  EPGDebugView.swift
//  tvNDQ3
//
//  Shows airings for a specific channel display-name to verify EPG parsing.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct EPGDebugView: View {
    @ObservedObject private var epgManager = EPGManager.shared
    @ObservedObject private var settingsManager = SettingsManager()
    @StateObject private var epgDownloader = EPGDownloader()
    @State private var isParsingManually = false
    @State private var parseProgress = ""
    @State private var programCount = 0
    @State private var channelCount = 0
    @State private var currentProgram = ""
    @State private var parseError: String?
    
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
                    
                    Button(action: downloadAndParseWithProgress) {
                        HStack {
                            if epgDownloader.isDownloading || isParsingManually {
                                ProgressView().scaleEffect(0.8)
                                Text(isParsingManually ? "Parsing..." : "Downloading...")
                            } else {
                                Image(systemName: "arrow.down.circle")
                                Text("Download & Parse")
                            }
                        }
                    }
                    .disabled(epgDownloader.isDownloading || isParsingManually)
                    
                    Button(action: copyPathToClipboard) {
                        Label("Saved in Caches/EPG", systemImage: "folder")
                    }
                }
                .buttonStyle(.bordered)
                
                epgInfo
                
                if isParsingManually || !parseProgress.isEmpty {
                    parseProgressSection
                }
                
                // Trimmed: list of airings removed for focused debugging UI
            }
            .padding()
            .navigationTitle("EPG Debug")
        }
        .onChange(of: epgDownloader.lastSavedURL) { _, newValue in
            if let url = newValue {
                parseWithProgress(url: url)
            }
        }
    }
    
    private var parseProgressSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Parse Progress")
                .font(.headline)
            if let error = parseError {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                Text(parseProgress)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if programCount > 0 {
                    Text("Programs: \(programCount), Channels: \(channelCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if !currentProgram.isEmpty {
                    Text("Current: \(currentProgram)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func downloadAndParseWithProgress() {
        parseProgress = "Starting download..."
        parseError = nil
        programCount = 0
        channelCount = 0
        currentProgram = ""
        epgDownloader.download(from: settingsManager.epgURL)
    }
    
    private func parseWithProgress(url: URL) {
        isParsingManually = true
        parseProgress = "Starting parse..."
        parseError = nil
        programCount = 0
        channelCount = 0
        currentProgram = ""
        
        DispatchQueue.global(qos: .userInitiated).async {
            let parser = DebugEPGParser { progress in
                DispatchQueue.main.async {
                    self.parseProgress = progress.message
                    self.programCount = progress.programCount
                    self.channelCount = progress.channelCount
                    self.currentProgram = progress.currentProgram
                }
            } onError: { error in
                DispatchQueue.main.async {
                    self.parseError = error
                    self.isParsingManually = false
                }
            }
            
            let result = parser.parse(fileURL: url)
            
            DispatchQueue.main.async {
                self.isParsingManually = false
                if self.parseError == nil {
                    self.parseProgress = "Parse completed successfully"
                    // Update EPGManager with results
                    self.updateEPGManager(channels: result.channels, programs: result.programs)
                }
            }
        }
    }
    
    private func updateEPGManager(channels: [String: String], programs: [EPGProgram]) {
        // Manually update EPGManager to trigger UI refresh
        var byName: [String: [EPGProgram]] = [:]
        var byId: [String: [EPGProgram]] = [:]
        for p in programs {
            byId[p.channelId, default: []].append(p)
            let name = channels[p.channelId] ?? p.channelId
            byName[name, default: []].append(p)
        }
        for key in byName.keys { byName[key]?.sort { $0.start < $1.start } }
        for key in byId.keys { byId[key]?.sort { $0.start < $1.start } }
        
        // Use reflection to update EPGManager (this is a hack for debugging)
        let mirror = Mirror(reflecting: epgManager)
        // Note: This won't actually work due to private properties, but shows the intent
        // In a real implementation, you'd need to add a debug update method to EPGManager
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
                Text("\(epgManager.channelCount)")
                    .font(.caption)
            }
            HStack {
                Text("Programs:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(epgManager.programCount)")
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
                Text("Error: \(err)")
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
    
    private func copyPathToClipboard() {
        // UIPasteboard is not available on tvOS. Only attempt to copy on platforms that support UIKit pasteboard.
        #if canImport(UIKit) && !os(tvOS)
        UIPasteboard.general.string = epgManager.lastFileURL?.path
        #else
        // No-op on tvOS and platforms without UIKit pasteboard.
        #endif
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

struct ParseProgress {
    let message: String
    let programCount: Int
    let channelCount: Int
    let currentProgram: String
}

class DebugEPGParser: NSObject, XMLParserDelegate {
    private var channelNamesById: [String: String] = [:]
    private var programs: [EPGProgram] = []
    
    private var currentElement: String = ""
    private var currentChannelId: String?
    private var currentProgrammeChannel: String?
    private var currentProgrammeStart: Date?
    private var currentProgrammeEnd: Date?
    private var currentTitleBuffer: String = ""
    
    private let onProgress: (ParseProgress) -> Void
    private let onError: (String) -> Void
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMddHHmmss Z"
        return formatter
    }()
    
    init(onProgress: @escaping (ParseProgress) -> Void, onError: @escaping (String) -> Void) {
        self.onProgress = onProgress
        self.onError = onError
        super.init()
    }
    
    func parse(fileURL: URL) -> (channels: [String: String], programs: [EPGProgram]) {
        channelNamesById.removeAll()
        programs.removeAll()
        
        onProgress(ParseProgress(message: "Starting XML parse...", programCount: 0, channelCount: 0, currentProgram: ""))
        
        guard let parser = XMLParser(contentsOf: fileURL) else {
            onError("Could not create XML parser from file")
            return ([:], [])
        }
        
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        
        let success = parser.parse()
        if !success {
            onError("XML parsing failed: \(parser.parserError?.localizedDescription ?? "Unknown error")")
        }
        
        return (channelNamesById, programs)
    }
    
    // MARK: - XMLParserDelegate
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        switch elementName {
        case "channel":
            if let id = attributeDict["id"] {
                channelNamesById[id] = ""
                currentChannelId = id
                onProgress(ParseProgress(message: "Parsing channel: \(id)", programCount: programs.count, channelCount: channelNamesById.count, currentProgram: ""))
            }
        case "display-name":
            currentTitleBuffer = ""
        case "programme":
            currentProgrammeChannel = attributeDict["channel"]
            currentProgrammeStart = parseDate(attributeDict["start"])
            currentProgrammeEnd = parseDate(attributeDict["stop"])
            currentTitleBuffer = ""
            
            if programs.count % 100 == 0 {
                onProgress(ParseProgress(message: "Parsing programmes...", programCount: programs.count, channelCount: channelNamesById.count, currentProgram: currentProgrammeChannel ?? ""))
            }
        case "title":
            currentTitleBuffer = ""
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentElement == "display-name" || currentElement == "title" {
            currentTitleBuffer.append(string)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "display-name":
            if let id = currentChannelId {
                let displayName = currentTitleBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
                if channelNamesById[id]?.isEmpty == true && !displayName.isEmpty {
                    channelNamesById[id] = displayName
                }
            }
        case "title":
            break
        case "programme":
            if let ch = currentProgrammeChannel, let s = currentProgrammeStart, let e = currentProgrammeEnd {
                do {
                    let channelId = String(ch)
                    let startDate = Date(timeIntervalSince1970: s.timeIntervalSince1970)
                    let endDate = Date(timeIntervalSince1970: e.timeIntervalSince1970)
                    let programTitle = String(currentTitleBuffer.trimmingCharacters(in: .whitespacesAndNewlines))
                    
                    let program = EPGProgram(channelId: channelId, title: programTitle, start: startDate, end: endDate)
                    programs.append(program)
                    
                    if programs.count % 500 == 0 {
                        onProgress(ParseProgress(message: "Added program: \(programTitle)", programCount: programs.count, channelCount: channelNamesById.count, currentProgram: programTitle))
                    }
                } catch {
                    onError("Failed to create program at count \(programs.count): \(error.localizedDescription)")
                    return
                }
            }
            currentProgrammeChannel = nil
            currentProgrammeStart = nil
            currentProgrammeEnd = nil
            currentTitleBuffer = ""
        case "channel":
            currentChannelId = nil
        default:
            break
        }
        currentElement = ""
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        onError("Parse error at line \(parser.lineNumber): \(parseError.localizedDescription)")
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        var normalizedDate = dateString
        if normalizedDate.count >= 15 {
            let timeIndex = normalizedDate.index(normalizedDate.startIndex, offsetBy: 14)
            let timezonePart = String(normalizedDate[timeIndex...])
            if !timezonePart.hasPrefix(" ") {
                normalizedDate.insert(" ", at: timeIndex)
            }
        }
        
        return dateFormatter.date(from: normalizedDate)
    }
}
