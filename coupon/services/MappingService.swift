//
//  MappingService.swift
//  coupon
//
//  Created by WAN Tung Lok on 17/11/2019.
//  Copyright © 2019 IBM. All rights reserved.
//

import Foundation

class MappingService: NSObject {

    let fileService: FileService
    let webService: WebService
    
    init(_ fileService: FileService, _ webService: WebService) {
        self.fileService = fileService
        self.webService = webService
    }
    
    func get(_ data: Data?) -> [Mapping]? {
        guard let data = data, let jsonArray = webService.toJSONArray(data) else {
            return nil
        }
        var mappings: [Mapping] = []
        for jsonObject in jsonArray {
            let mapping = Mapping(jsonObject)
            mappings.append(mapping)
        }
        return mappings
    }

    func get() -> [Mapping]? {
        guard var path = fileService.documentDirectory else {
            return nil
        }
        path.appendPathComponent("mappings.dat");
        var mappings: [Mapping]?
        if (fileService.fileExists(path)) {
            guard let data = try? Data(contentsOf: path) else {
                return nil
            }
            mappings = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [Mapping]
        }
        return mappings
    }

    func save(_ mappings: [Mapping]?) {
        guard let mappings = mappings, var path = fileService.documentDirectory else {
            return
        }
        path.appendPathComponent("mappings.dat");
        do {
            try NSKeyedArchiver.archivedData(withRootObject: mappings, requiringSecureCoding: false).write(to: path)
        } catch {
            print(error)
        }
    }
    
    func merge(_ mappings: [Mapping]?, with: [Mapping]?) -> [Mapping]? {
        var dict: [Int:Mapping] = [:]
        if let mappings = mappings {
            for mapping in mappings {
                dict[mapping.id] = mapping
            }
        }
        if let mappings = with {
            for mapping in mappings {
                if let oldMapping = dict[mapping.id] {
                    if mapping.timestamp > oldMapping.timestamp {
                        dict[mapping.id] = mapping
                    }
                } else {
                    dict[mapping.id] = mapping
                }
            }
        }
        var newMappings: [Mapping] = []
        for (_, mapping) in dict {
            newMappings.append(mapping)
        }
        return newMappings
    }
    
    func download(_ mappings: [Mapping], completion: @escaping ()->()) {
        var temp = mappings
        let mapping = temp.removeFirst()
        print("download content for mapping: \(mapping.id)")
        var filePath = self.fileService.savePath(urlString: mapping.imageAddress)
        if (fileService.fileExists(filePath)) {
            filePath = self.fileService.savePath(urlString: mapping.videoAddress)
            if (self.fileService.fileExists(filePath)) {
                if (temp.count > 0) {
                    self.download(temp, completion: completion)
                } else {
                    completion()
                }
            } else {
                self.webService.downloadFile(mapping.videoAddress) { (ok, fileURL) in
                    self.fileService.moveFile(at: fileURL, to: filePath)
                    if (temp.count > 0) {
                        self.download(temp, completion: completion)
                    } else {
                        completion()
                    }
                }
            }
        } else {
            webService.downloadFile(mapping.imageAddress) { (ok, fileURL) in
                self.fileService.moveFile(at: fileURL, to: filePath)
                filePath = self.fileService.savePath(urlString: mapping.videoAddress)
                if (self.fileService.fileExists(filePath)) {
                    if (temp.count > 0) {
                        self.download(temp, completion: completion)
                    } else {
                        completion()
                    }
                } else {
                    self.webService.downloadFile(mapping.videoAddress) { (ok, fileURL) in
                        self.fileService.moveFile(at: fileURL, to: filePath)
                        if (temp.count > 0) {
                            self.download(temp, completion: completion)
                        } else {
                            completion()
                        }
                    }
                }
            }
        }
    }
}
