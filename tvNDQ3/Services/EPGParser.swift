//
//  EPGParser.swift
//  tvNDQ3
//
//  XMLTV parser extracting channel display-names and programme title windows.
//  Based on approach from https://github.com/Rubenfer/XMLTV
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
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMddHHmmss Z"
        return formatter
    }()
    
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
        
        switch elementName {
        case "channel":
            if let id = attributeDict["id"] {
                channelNamesById[id] = ""
                currentChannelId = id
            }
        case "display-name":
            currentTitleBuffer = ""
        case "programme":
            currentProgrammeChannel = attributeDict["channel"]
            currentProgrammeStart = parseDate(attributeDict["start"])
            currentProgrammeEnd = parseDate(attributeDict["stop"])
            currentTitleBuffer = ""
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
            // Keep buffer for programme end
            break
        case "programme":
            if let ch = currentProgrammeChannel, let s = currentProgrammeStart, let e = currentProgrammeEnd {
                // Create local copies to avoid any threading issues
                let channelId = String(ch)
                let startDate = Date(timeIntervalSince1970: s.timeIntervalSince1970)
                let endDate = Date(timeIntervalSince1970: e.timeIntervalSince1970)
                let programTitle = String(currentTitleBuffer.trimmingCharacters(in: .whitespacesAndNewlines))
                
                let program = EPGProgram(channelId: channelId, title: programTitle, start: startDate, end: endDate)
                programs.append(program)
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
    
    // MARK: - Helpers
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        // Handle different XMLTV date formats
        var normalizedDate = dateString
        
        // Handle timezone formats: +0000 vs +00:00
        if normalizedDate.count >= 15 {
            let timeIndex = normalizedDate.index(normalizedDate.startIndex, offsetBy: 14)
            let timezonePart = String(normalizedDate[timeIndex...])
            
            // If timezone doesn't start with space, add it
            if !timezonePart.hasPrefix(" ") {
                normalizedDate.insert(" ", at: timeIndex)
            }
        }
        
        return dateFormatter.date(from: normalizedDate)
    }
}
