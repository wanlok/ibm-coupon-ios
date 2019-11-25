//
//  WebService.swift
//  coupon
//
//  Created by WAN Tung Lok on 17/11/2019.
//  Copyright © 2019 IBM. All rights reserved.
//

import Foundation

class WebService: NSObject {
    
    func toJSONArray(_ data: Data) -> [[String: Any?]]? {
       let json = try? JSONSerialization.jsonObject(with: data, options: [])
       return json as? [[String: Any?]]
    }
    
    func toJSONObject(_ data: Data) -> [String: Any?]? {
       let json = try? JSONSerialization.jsonObject(with: data, options: [])
       return json as? [String: Any?]
    }
    
    func getJSONData(_ urlString: String, completion: @escaping (Bool, Data?)->()) {
        guard let url = URL(string: urlString) else {
            completion(false, nil)
            return
        }
        var request = URLRequest(url: url)
        request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData
        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion(false, nil)
                return
            }
            completion(true, data)
        }
        dataTask.resume()
    }
    
    func postJSONData(_ urlString: String, params: String, completion: @escaping (Bool, Data?)->()) {
        guard let url = URL(string: urlString) else {
            completion(false, nil)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let data = params.data(using: .utf8) {
            request.httpBody = data
        }
        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion(false, nil)
                return
            }
            completion(true, data)
        }
        dataTask.resume()
    }
    
    func jsonPostJSONData(_ urlString: String, params: [String: Any], token: String, completion: @escaping (Bool, Data?)->()) {
        guard let url = URL(string: urlString) else {
            completion(false, nil)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        if let data = try? JSONSerialization.data(withJSONObject: params) {
            request.httpBody = data
        }
        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
//            print(data)
//            print(response)
//            print(error)
            guard let data = data else {
                completion(false, nil)
                return
            }
            completion(true, data)
        }
        dataTask.resume()
    }
    
    private func isValid(_ url: URL, _ response: URLResponse?, _ error: Error?) -> Bool {
        var valid = true
        if let httpResponse = response as? HTTPURLResponse {
            if (httpResponse.statusCode >= 400) {
                NSLog("NS: httpError, statusCode=\(httpResponse.statusCode), url=\(url.absoluteString)")
                valid = false
            }
        }
        if let error = error {
            NSLog("NS: responseError, url=\(url.absoluteString), error=\(error.localizedDescription)")
            valid = false
        }
        return valid
    }
    
    public func downloadFile(_ urlString: String, completion: @escaping (Bool, URL?)->()) {
        guard let url = URL(string: urlString) else {
            return
        }
        var request = URLRequest(url: url)
        request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData
        let downloadTask = URLSession.shared.downloadTask(with: request) { location, response, error in
            guard self.isValid(url, response, error) else {
                completion(false, nil)
                return
            }
            NSLog("NS: downloadFile, Downloaded at directory:\(String(describing: location))")
            completion(true, location)
        }
        downloadTask.resume()
    }
}
