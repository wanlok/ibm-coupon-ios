//
//  ARState.swift
//  coupon
//
//  Created by WAN Tung Lok on 19/11/2019.
//  Copyright © 2019 IBM. All rights reserved.
//

import UIKit
import AVKit

class ARState: NSObject {
    var key: String
    
    private var alpha: CGFloat
    private var reverse: Bool
    
    var blink: Int
    var playing: Bool
    var completed: Bool
    
    var player: AVPlayer?
    var playerCompletion: (()->())?
    
    init(_ key: String) {
        self.key = key
        alpha = 0
        reverse = false
        blink = 0
        playing = false
        completed = false
    }
    
    func reset() {
        print("video state resetted: \(key)")
        alpha = 0
        reverse = false
        blink = 0
        playing = false
        completed = false
    }
    
    func color(_ frames: Double) -> UIColor {
        alpha = alpha + CGFloat(frames * (reverse ? -1 : 1)) * 4
        if (alpha > 1) {
            reverse = true
        } else if (alpha < 0) {
            reverse = false
            blink = blink + 1
        }
        return UIColor.init(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: alpha)
    }
    
    func setupPlayer(url: URL, withSound: Bool) {
        player = AVPlayer(url: url)
        player?.volume = withSound ? 1 : 0
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: .main) { [weak self] _ in
            guard let self = self else {
                return
            }
            print("video play finished: \(self.key)")
            self.completed = true
            self.playerCompletion?()
        }
    }
    
    func playVideo() {
        guard !playing else {
            return
        }
        playing = true
        player?.seek(to: .zero)
        player?.play()
    }
}
