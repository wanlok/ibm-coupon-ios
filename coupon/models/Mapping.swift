//
//  Mapping.swift
//  coupon
//
//  Created by WAN Tung Lok on 17/11/2019.
//  Copyright © 2019 IBM. All rights reserved.
//

import Foundation

class Mapping: NSObject, NSCoding {
    var id: Int
    var imageAddress: String
    var videoAddress: String
    var width: Double
    var sound: Bool
    var timestamp: Int
    var points: Int
    var trigger: Bool
    
    init(_ jsonObject: [String: Any?]) {
        if let id = jsonObject["id"] as? Int {
            self.id = id
        } else {
            id = 0
        }
        if let acf = jsonObject["acf"] as? [String: Any?] {
            if let imageAddress = acf["triggerImageURL"] as? String {
                self.imageAddress = imageAddress
            } else {
                imageAddress = ""
            }
            if let videoAddress = acf["videoURL"] as? String {
                self.videoAddress = videoAddress
            } else {
                videoAddress = ""
            }
            if let triggerPhysicalWidth = acf["triggerPhysicalWidth"] as? String, let width = Double(triggerPhysicalWidth) {
                self.width = width
            } else {
                width = 0
            }
            if let sound = acf["sound"] as? Bool {
                self.sound = sound
            } else {
                sound = false
            }
            if let points = acf["points"] as? Int {
                self.points = points
            } else {
                points = 0
            }
            if let trigger = acf["triggerToRegister"] as? Bool {
                self.trigger = trigger
            } else {
                trigger = false
            }
        } else {
            imageAddress = ""
            videoAddress = ""
            width = 0
            sound = false
            points = 0
            trigger = false
        }
        if let modifiedGMT = jsonObject["modified_gmt"] as? String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = dateFormatter.date(from: modifiedGMT) {
                timestamp = date.millisecondsSince1970
            } else {
                timestamp = 0
            }
        } else {
            timestamp = 0
        }
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(imageAddress, forKey: "imageAddress")
        aCoder.encode(videoAddress, forKey: "videoAddress")
        aCoder.encode(width, forKey: "width")
        aCoder.encode(sound, forKey: "sound")
        aCoder.encode(points, forKey: "points")
        aCoder.encode(trigger, forKey: "trigger")
        aCoder.encode(timestamp, forKey: "timestamp")
    }
    
    required init?(coder aDecoder: NSCoder) {
        id = Int(aDecoder.decodeInt64(forKey: "id"))
        if let imageAddress = aDecoder.decodeObject(forKey: "imageAddress") as? String {
            self.imageAddress = imageAddress
        } else {
            imageAddress = ""
        }
        if let videoAddress = aDecoder.decodeObject(forKey: "videoAddress") as? String {
            self.videoAddress = videoAddress
        } else {
            videoAddress = ""
        }
        width = aDecoder.decodeDouble(forKey: "width")
        sound = aDecoder.decodeBool(forKey: "sound")
        points = Int(aDecoder.decodeInt64(forKey: "points"))
        trigger = aDecoder.decodeBool(forKey: "trigger")
        timestamp = Int(aDecoder.decodeInt64(forKey: "timestamp"))
    }
}
