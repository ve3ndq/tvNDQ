//
//  EPGDownloader.swift
//  tvNDQ3
//
//  Created by Xcode Assistant on 2025-09-20.
//

import Foundation
import Combine

class EPGDownloader: NSObject, ObservableObject {
    @Published var isDownloading = false
    @Published var progress: Double = 0.0 // 0.0...1.0
    @Published var errorMessage: String?
    @Published var lastSavedURL: URL?
    @Published var totalBytesExpected: Int64 = 0
    @Published var bytesReceived: Int64 = 0
    @Published var lastResult: String?
    
    private var task: URLSessionDownloadTask?
    private var session: URLSession?
    private let etagKeyPrefix = "EPGCache_ETag_"
    private let lastModKeyPrefix = "EPGCache_LastMod_"
    
    func download(from urlString: String) {
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid EPG URL"
            return
        }
        if isDownloading { return }
        errorMessage = nil
        lastResult = nil
        isDownloading = true
        progress = 0
        totalBytesExpected = 0
        bytesReceived = 0
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        self.session = session

        var request = URLRequest(url: url)
        // Add conditional headers if available
        if let etag = UserDefaults.standard.string(forKey: etagKey(urlString)) {
            request.addValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        if let lastMod = UserDefaults.standard.string(forKey: lastModKey(urlString)) {
            request.addValue(lastMod, forHTTPHeaderField: "If-Modified-Since")
        }

        task = session.downloadTask(with: request)
        task?.resume()
    }
    
    func cancel() {
        task?.cancel()
        task = nil
        session?.invalidateAndCancel()
        session = nil
        DispatchQueue.main.async {
            self.isDownloading = false
        }
    }
    
    private func storageDirectory() throws -> URL {
        let fm = FileManager.default
        let base = fm.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("EPG", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    private func saveToStorage(tempURL: URL, originalURL: URL) throws -> URL {
        let fm = FileManager.default
        let dir = try storageDirectory()
        let filename = originalURL.lastPathComponent.isEmpty ? "guide.xml" : originalURL.lastPathComponent
        let dest = dir.appendingPathComponent(filename)
        if fm.fileExists(atPath: dest.path) {
            try fm.removeItem(at: dest)
        }
        try fm.moveItem(at: tempURL, to: dest)
        return dest
    }

    private func cachedFileURL(for originalURL: URL) -> URL? {
        do {
            let dir = try storageDirectory()
            let filename = originalURL.lastPathComponent.isEmpty ? "guide.xml" : originalURL.lastPathComponent
            let dest = dir.appendingPathComponent(filename)
            return FileManager.default.fileExists(atPath: dest.path) ? dest : nil
        } catch {
            return nil
        }
    }

    private func etagKey(_ urlString: String) -> String { etagKeyPrefix + urlString }
    private func lastModKey(_ urlString: String) -> String { lastModKeyPrefix + urlString }
}

extension EPGDownloader: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async {
            if totalBytesExpectedToWrite > 0 {
                let p = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                self.progress = p
                self.totalBytesExpected = totalBytesExpectedToWrite
            } else {
                // Unknown size; keep progress indeterminate (0), still show bytes
                self.progress = 0
            }
            self.bytesReceived = totalBytesWritten
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let originalURL = downloadTask.originalRequest?.url
        do {
            let dest = try self.saveToStorage(tempURL: location, originalURL: originalURL ?? URL(fileURLWithPath: "guide.xml"))
            if let http = downloadTask.response as? HTTPURLResponse {
                if let etag = http.allHeaderFields["ETag"] as? String {
                    UserDefaults.standard.set(etag, forKey: etagKey(originalURL?.absoluteString ?? ""))
                }
                if let lastMod = http.allHeaderFields["Last-Modified"] as? String {
                    UserDefaults.standard.set(lastMod, forKey: lastModKey(originalURL?.absoluteString ?? ""))
                }
            }
            DispatchQueue.main.async {
                self.lastSavedURL = dest
                if let size = (try? FileManager.default.attributesOfItem(atPath: dest.path)[.size] as? NSNumber)?.int64Value {
                    self.bytesReceived = size
                    self.totalBytesExpected = max(self.totalBytesExpected, size)
                }
                self.lastResult = "Download complete"
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.lastResult = "Failed: \(error.localizedDescription)"
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let http = task.response as? HTTPURLResponse
        DispatchQueue.main.async {
            self.isDownloading = false
            if let http = http, http.statusCode == 304 {
                // Not modified: reuse cached file
                if let reqURL = task.originalRequest?.url, let cached = self.cachedFileURL(for: reqURL) {
                    self.lastSavedURL = cached
                    if let size = (try? FileManager.default.attributesOfItem(atPath: cached.path)[.size] as? NSNumber)?.int64Value {
                        self.bytesReceived = size
                        self.totalBytesExpected = max(self.totalBytesExpected, size)
                    }
                }
                self.lastResult = "Not modified (using cached)"
                self.errorMessage = nil
            } else if let error = error as NSError?, error.code != NSURLErrorCancelled {
                self.errorMessage = error.localizedDescription
                self.lastResult = "Failed: \(error.localizedDescription)"
            } else if (error as NSError?)?.code == NSURLErrorCancelled {
                self.lastResult = "Cancelled"
            }
        }
        session.finishTasksAndInvalidate()
        self.session = nil
        self.task = nil
    }
}
