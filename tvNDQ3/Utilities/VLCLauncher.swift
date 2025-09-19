//
//  VLCLauncher.swift
//  tvNDQ3
//
//  Created by Nathan Dykstra on 2025-09-18.
//

import Foundation
import UIKit

class VLCLauncher {
    static let shared = VLCLauncher()
    
    private init() {}
    
    func playChannel(_ channel: Channel, completion: @escaping (Bool) -> Void) {
        playURL(channel.url, title: channel.name, completion: completion)
    }
    
    func playURL(_ urlString: String, title: String? = nil, completion: @escaping (Bool) -> Void) {
        guard let encodedURL = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            completion(false)
            return
        }
        
        // Try VLC first
        let vlcURLString = "vlc://\(encodedURL)"
        if let vlcURL = URL(string: vlcURLString) {
            UIApplication.shared.open(vlcURL) { success in
                if success {
                    completion(true)
                } else {
                    // If VLC fails, try VLC-X
                    self.tryVLCX(encodedURL: encodedURL, completion: completion)
                }
            }
        } else {
            completion(false)
        }
    }
    
    private func tryVLCX(encodedURL: String, completion: @escaping (Bool) -> Void) {
        let vlcxURLString = "vlc-x-callback://x-callback-url/stream?url=\(encodedURL)"
        if let vlcxURL = URL(string: vlcxURLString) {
            UIApplication.shared.open(vlcxURL) { success in
                if success {
                    completion(true)
                } else {
                    // If both VLC schemes fail, try generic HTTP scheme
                    self.tryGenericHTTP(encodedURL: encodedURL, completion: completion)
                }
            }
        } else {
            completion(false)
        }
    }
    
    private func tryGenericHTTP(encodedURL: String, completion: @escaping (Bool) -> Void) {
        // Try opening the raw URL - this might work with other video players
        if let url = URL(string: encodedURL.removingPercentEncoding ?? encodedURL) {
            UIApplication.shared.open(url, options: [:]) { success in
                completion(success)
            }
        } else {
            completion(false)
        }
    }
    
    func isVLCInstalled() -> Bool {
        guard let vlcURL = URL(string: "vlc://") else { return false }
        return UIApplication.shared.canOpenURL(vlcURL)
    }
    
    func isVLCXInstalled() -> Bool {
        guard let vlcxURL = URL(string: "vlc-x-callback://") else { return false }
        return UIApplication.shared.canOpenURL(vlcxURL)
    }
}