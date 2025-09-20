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
    
    private var task: URLSessionDownloadTask?
    private var session: URLSession?
    
    func download(from urlString: String) {
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid EPG URL"
            return
        }
        if isDownloading { return }
        errorMessage = nil
        isDownloading = true
        progress = 0
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        self.session = session
        task = session.downloadTask(with: url)
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
    
    private func saveToDocuments(tempURL: URL, originalURL: URL) throws -> URL {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filename = originalURL.lastPathComponent.isEmpty ? "guide.xml" : originalURL.lastPathComponent
        let dest = docs.appendingPathComponent(filename)
        if fm.fileExists(atPath: dest.path) {
            try fm.removeItem(at: dest)
        }
        try fm.moveItem(at: tempURL, to: dest)
        return dest
    }
}

extension EPGDownloader: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let p = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.progress = p
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let originalURL = downloadTask.originalRequest?.url
        do {
            let dest = try self.saveToDocuments(tempURL: location, originalURL: originalURL ?? URL(fileURLWithPath: "guide.xml"))
            DispatchQueue.main.async {
                self.lastSavedURL = dest
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            self.isDownloading = false
            if let error = error as NSError?, error.code != NSURLErrorCancelled {
                self.errorMessage = error.localizedDescription
            }
        }
        session.finishTasksAndInvalidate()
        self.session = nil
        self.task = nil
    }
}
