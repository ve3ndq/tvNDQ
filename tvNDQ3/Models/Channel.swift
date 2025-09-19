//
//  Channel.swift
//  tvNDQ3
//
//  Created by Nathan Dykstra on 2025-09-18.
//

import Foundation

struct Channel: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let url: String
    let group: String?
    let logoURL: String?
    
    init(name: String, url: String, group: String? = nil, logoURL: String? = nil) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.group = group
        self.logoURL = logoURL
    }
}

struct ChannelGroup: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let channels: [Channel]
    
    init(name: String, channels: [Channel]) {
        self.name = name
        self.channels = channels
    }
}