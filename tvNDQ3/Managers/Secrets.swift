//
//  Secrets.swift
//  tvNDQ3
//
//  Created by Xcode Assistant on 2025-09-20.
//

import Foundation

/// Central place to store default/fallback configuration values.
/// Replace `defaultM3UURL` with your preferred default feed URL.
struct Secrets {
    /// Default M3U playlist URL used when no value is stored in UserDefaults.
    /// Update this to your actual default URL if needed.
    static let defaultM3UURL: String = "https://iptv-org.github.io/iptv/index.m3u"
}
