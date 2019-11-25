//
//  FileService.swift
//  coupon
//
//  Created by WAN Tung Lok on 17/11/2019.
//  Copyright © 2019 IBM. All rights reserved.
//

import Foundation

class FileService: NSObject {

    let fileManager = FileManager.default
    
    var documentDirectory: URL? {
        get {
            guard let documentDirectory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false) else {
                return nil
            }
            return documentDirectory
        }
    }
    
    func directoryExists(_ url: URL) -> Bool {
        var isDirectory = ObjCBool(true)
        let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
    
    func isDirectory(_ url: URL) -> Bool {
        var isDirectory = ObjCBool(true)
        _ = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }
    
    func fileExists(_ url: URL?) -> Bool {
        guard let url = url else {
            return false
        }
        return fileManager.fileExists(atPath: url.path)
    }
    
    func createDirectory(pathSegments: [String]) {
//        var success = false
        guard var documentDirectory = documentDirectory else {
//            return success
            return
        }
        for pathSegment in pathSegments {
            documentDirectory.appendPathComponent(pathSegment)
        }
        if (!directoryExists(documentDirectory)) {
            do {
                try fileManager.createDirectory(at: documentDirectory, withIntermediateDirectories: true, attributes: nil)
//                success = true
            } catch {
                print(error)
            }
        }
//        return success
    }
    
    func removeDirectory(pathSegments: [String]) {
        guard var documentDirectory = documentDirectory, pathSegments.count > 0 else {
            return
        }
        for pathSegment in pathSegments {
            documentDirectory.appendPathComponent(pathSegment)
        }
        if (directoryExists(documentDirectory)) {
            do {
                try fileManager.removeItem(at: documentDirectory)
            } catch {
                print(error)
            }
        }
    }
    
    func moveFile(at: URL?, to: URL?) {
        guard let at = at, let to = to else {
            return
        }
        do {
            try fileManager.moveItem(at: at, to: to)
        } catch {
            print(error)
        }
    }
    
    func list(_ url: URL?) -> [URL] {
        var results: [URL] = []
        guard let url = url else {
            return results
        }
        var urls: [URL]? = nil
        do {
            urls = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        } catch {
            print(error)
        }
        if let urls = urls {
            for url in urls {
                if (isDirectory(url)) {
                    results += list(url)
                } else {
                    results.append(url)
                }
            }
        }
        return results
    }
    
    func savePath(urlString: String) -> URL? {
        var documentDirectory = self.documentDirectory
        documentDirectory?.appendPathComponent((urlString as NSString).lastPathComponent)
        return documentDirectory
    }
}
