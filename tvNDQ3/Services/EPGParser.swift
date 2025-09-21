//
//  EPGParser.swift
//  tvNDQ3
//
//  Minimal XMLTV parser extracting channel display-names and programme title windows.
//

import Foundation

struct EPGProgram: Identifiable, Hashable {
    let id = UUID()
    let channelId: String
    let title: String
    let start: Date
    let end: Date
}

final class EPGParser: NSObject, XMLParserDelegate {
    private(set) var channelNamesById: [String: String] = [:]
    private(set) var programs: [EPGProgram] = []
    
    private var currentElement: String = ""
    private var currentChannelId: String?
    private var currentProgrammeChannel: String?
    private var currentProgrammeStart: Date?
    private var currentProgrammeEnd: Date?
    private var currentTitleBuffer: String = ""
    
    private let dateFormats: [String] = [
        "yyyyMMddHHmmss ZZZZZ",
        "yyyyMMddHHmmss",
        "yyyyMMddHHmm ZZZZZ",
        "yyyyMMddHHmm"
    ]
    
    private func createDateFormatters() -> [DateFormatter] {
        let locale = Locale(identifier: "en_US_POSIX")
        return dateFormats.map { fmt in
            let df = DateFormatter()
            df.locale = locale
            df.dateFormat = fmt
            return df
        }
    }
    
    func parse(data: Data) -> (channels: [String: String], programs: [EPGProgram]) {
        channelNamesById.removeAll()
        programs.removeAll()
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        parser.parse()
        return (channelNamesById, programs)
    }
    
    func parse(fileURL: URL) -> (channels: [String: String], programs: [EPGProgram]) {
        channelNamesById.removeAll()
        programs.removeAll()
        if let parser = XMLParser(contentsOf: fileURL) {
            parser.delegate = self
            parser.shouldProcessNamespaces = false
            parser.parse()
        } else {
            // Fallback to reading data if needed
            if let data = try? Data(contentsOf: fileURL) {
                _ = parse(data: data)
            }
        }
        return (channelNamesById, programs)
    }
    
    // MARK: - XMLParserDelegate
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "channel" {
            if let id = attributeDict["id"] {
                channelNamesById[id] = ""
                currentChannelId = id
            }
        } else if elementName == "display-name" {
            currentTitleBuffer = ""
        } else if elementName == "programme" {
            currentProgrammeChannel = attributeDict["channel"]
            currentProgrammeStart = parseDate(attributeDict["start"])
            currentProgrammeEnd = parseDate(attributeDict["stop"]) ?? parseDate(attributeDict["end"]) // some feeds use stop
            currentTitleBuffer = ""
        } else if elementName == "title" {
            currentTitleBuffer = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentElement == "display-name" || currentElement == "title" {
            currentTitleBuffer.append(string)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "display-name" {
            if let id = currentChannelId {
                let existingEmpty = (channelNamesById[id]?.isEmpty ?? true)
                if existingEmpty {
                    channelNamesById[id] = currentTitleBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        } else if elementName == "title" {
            // just keep buffer; handled when programme ends
        } else if elementName == "programme" {
            if let ch = currentProgrammeChannel, let s = currentProgrammeStart, let e = currentProgrammeEnd {
                let title = currentTitleBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
                programs.append(EPGProgram(channelId: ch, title: title.isEmpty ? "" : title, start: s, end: e))
            }
            currentProgrammeChannel = nil
            currentProgrammeStart = nil
            currentProgrammeEnd = nil
            currentTitleBuffer = ""
        }
    if elementName == "channel" { currentChannelId = nil }
    currentElement = ""
    }
    
    // MARK: - Helpers
    private func parseDate(_ raw: String?) -> Date? {
        guard var s = raw else { return nil }
        // XMLTV may encode timezone like +0000 or +00:00; normalize to ZZZZZ
        if s.count >= 19, s[s.index(s.startIndex, offsetBy: 15)] != " " { // insert space before tz
            // e.g., yyyyMMddHHmmss+0000 -> yyyyMMddHHmmss +0000
            let idx = s.index(s.startIndex, offsetBy: 14)
            s.insert(" ", at: idx)
        }
        
        // Create formatters locally to avoid thread safety issues
        let locale = Locale(identifier: "en_US_POSIX")
        for fmt in dateFormats {
            let df = DateFormatter()
            df.locale = locale
            df.dateFormat = fmt
            if let d = df.date(from: s) { return d }
        }
        return nil
    }
}
