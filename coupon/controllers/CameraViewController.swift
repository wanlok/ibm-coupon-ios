//
//  CameraViewController.swift
//  coupon
//
//  Created by WAN Tung Lok on 20/11/2019.
//  Copyright © 2019 IBM. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class CameraViewController: BaseViewController, ARSCNViewDelegate {
    
    var webService: WebService?
    var fileService: FileService?
    
    @IBOutlet var sceneView: ARSCNView!
    //    @IBOutlet weak var focusView: HKICFocusView!
    
    @IBOutlet weak var bannerView: UIView!
    @IBOutlet weak var bannerLabel: UILabel!
    @IBOutlet weak var bannerCloseButton: UIButton!
    @IBOutlet weak var bannerButton: UIButton!
    
    @IBOutlet weak var bannerTriggerView: UIView!
    @IBOutlet weak var bannerTriggerLabel: UILabel!
    @IBOutlet weak var bannerTriggerButton: UIButton!
    @IBOutlet weak var bannerTriggerCloseButton: UIButton!
    
    @IBOutlet weak var loadingView: UIView!
    
    let frames: Double = 1 / 60
    let maxBlink: Int = 2
    
    var states: [String: ARState] = [:]
    
    var mappings: [Mapping]?
    
    var dict: [String: [String: Any]] {
        get {
            var dict: [String: [String: Any]] = [:]
            guard let fileService = fileService else {
                return dict
            }
            let urls = fileService.list(fileService.documentDirectory)
            guard  let mappings = mappings else {
                return dict
            }
            for mapping in mappings {
                let id = String(mapping.id)
                dict[id] = [:]
                dict[id]?["width"] = mapping.width
                dict[id]?["sound"] = mapping.sound
                let imageFileName = (mapping.imageAddress as NSString).lastPathComponent
                let videoFileName = (mapping.videoAddress as NSString).lastPathComponent
                for url in urls {
                    let fileName = url.lastPathComponent
                    if (fileName == imageFileName) {
                        dict[id]?["image"] = url
                    }
                    if (fileName == videoFileName) {
                        dict[id]?["video"] = url
                    }
                }
            }
            return dict
        }
    }
    
    @IBAction func onBannerTriggerButtonClick(_ sender: Any) {
        self.bannerView.isHidden = true
        self.bannerTriggerView.isHidden = true
        UserDefaults.standard.set(true, forKey: "triggered")
        navigationController?.pushViewController(RegistrationViewController(), animated: false)
    }
    
    func image(_ url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
    
    var arReferenceImages: Set<ARReferenceImage> {
        get {
            var arReferenceImages = Set<ARReferenceImage>()
            for (id, content) in dict {
                guard let url = content["image"] as? URL, let image = image(url), let cgImage = image.cgImage, let width = content["width"] as? Double else {
                    continue
                }
                let arReferenceImage = ARReferenceImage(cgImage, orientation: CGImagePropertyOrientation.up, physicalWidth: CGFloat(width))
                arReferenceImage.name = id
                arReferenceImages.insert(arReferenceImage)
            }
            return arReferenceImages
        }
    }
    
    @IBAction func onCloseButtonClick(_ sender: Any) {
        bannerView.isHidden = true
        bannerTriggerView.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bannerTriggerButton.layer.cornerRadius = 4
        
        fileService = FileService()
        webService = WebService()
        
        guard let fileService = fileService, let webService = webService else {
            return
        }
        
        let mappingService = MappingService(fileService, webService)
        
        webService.getJSONData("https://hktest-s3-services.s3-ap-southeast-1.amazonaws.com/spl-crm-demo/arcontent.json", completion: { (ok, data) in
            self.mappings = mappingService.merge(mappingService.get(), with: mappingService.get(data))
            
            guard let mappings = self.mappings else {
                return
            }
            
            mappingService.download(mappings, completion: {
                print("download completed")
                print(self.dict)
                
                for (id, content) in self.dict {
                    guard let url = content["video"] as? URL, let withSound = content["sound"] as? Bool else {
                        continue
                    }
                    let state = ARState(id)
                    state.setupPlayer(url: url, withSound: withSound)
                    self.states[id] = state
                }
                
                DispatchQueue.main.async {
                    self.loadingView.isHidden = true
                }
                
                let configuration = ARImageTrackingConfiguration()
                configuration.maximumNumberOfTrackedImages = 1
                configuration.trackingImages = self.arReferenceImages
                
                self.sceneView.delegate = self
                self.sceneView.showsStatistics = false
                self.sceneView.scene = SCNScene()
                self.sceneView.session.run(configuration)
            })
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARImageTrackingConfiguration()
        configuration.maximumNumberOfTrackedImages = 1
        configuration.trackingImages = self.arReferenceImages
        
        self.sceneView.delegate = self
        self.sceneView.showsStatistics = false
        self.sceneView.scene = SCNScene()
        self.sceneView.session.run(configuration)
    }
    
    //    @objc func handleBackButtonClick() {
    //        for (_, state) in states {
    //            state.player?.pause()
    //        }
    //        navigationController?.popViewController(animated: true)
    //    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        for (_, state) in states {
            state.player?.pause()
        }
        sceneView.session.pause()
    }
    
    func videoSize(url: URL) -> CGSize? {
        guard let track = AVURLAsset(url: url).tracks(withMediaType: .video).first else {
            return nil
        }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
    
    func videoSizeAspectFit(_ videoSize: CGSize, imageSize: CGSize) -> CGSize {
        var width = imageSize.width
        var height = videoSize.height * imageSize.width / videoSize.width
        if (height > imageSize.height) {
            width = videoSize.width * imageSize.height / videoSize.height
            height = imageSize.height
        }
        return CGSize(width: width, height: height)
    }
    
    func children(_ node: SCNNode, key: String) -> SCNNode? {
        var target: SCNNode? = nil
        for node in node.childNodes {
            if (node.name == key) {
                target = node
                break
            }
        }
        return target
    }
    
    @IBAction func onBannerButtonClick(_ sender: Any) {
        guard let url = URL(string: "http://www.dior.com") else {
            return
        }
        UIApplication.shared.open(url)
    }
    
    func append(_ node: SCNNode, _ imageAnchor: ARImageAnchor, _ key: String) {
        guard let state = states[key], let imageURL = dict[key]?["image"] as? URL, let image = image(imageURL), let videoURL = dict[key]?["video"] as? URL, let videoSize = videoSize(url: videoURL), let player = state.player else {
            return
        }
        
        let width = CGFloat(imageAnchor.referenceImage.physicalSize.width)
        let height = CGFloat(imageAnchor.referenceImage.physicalSize.height)
        
        let parentNode = SCNNode()
        parentNode.name = key
        parentNode.geometry = SCNPlane(width: width, height: height)
        parentNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        parentNode.position = SCNVector3(0, 0, 0)
        
        let scene = SKScene(size: image.size)
        scene.scaleMode = .aspectFit
        scene.backgroundColor = .clear
        
        let yScale: CGFloat = -1
        let position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        
        let backgroundNode = SKSpriteNode()
        backgroundNode.size = image.size
        backgroundNode.yScale = yScale
        backgroundNode.position = position
        backgroundNode.color = .black
        
        scene.addChild(backgroundNode)
        
        let videoNode = SKVideoNode(avPlayer: player)
        videoNode.yScale = yScale
        videoNode.position = position
        videoNode.size = videoSizeAspectFit(videoSize, imageSize: image.size)
        
        scene.addChild(videoNode)
        
        state.playerCompletion = {
            backgroundNode.isHidden = true
            videoNode.isHidden = true
        }
        
        let blinkNode = SKSpriteNode()
        blinkNode.size = image.size
        blinkNode.yScale = yScale
        blinkNode.position = position
        blinkNode.run(.repeatForever(.sequence([
            .run({
                if (!state.completed) {
                    if (!state.playing) {
                        if (state.blink < self.maxBlink) {
                            backgroundNode.isHidden = true
                            videoNode.isHidden = true
                            state.player?.pause()
                            blinkNode.color = state.color(self.frames)
                        } else if (state.blink == self.maxBlink) {
                            backgroundNode.isHidden = false
                            videoNode.isHidden = false
                            state.playVideo()
                        }
                    }
                }
            }),
            .wait(forDuration: frames)
            ])))
        
        scene.addChild(blinkNode)
        
        parentNode.geometry?.firstMaterial?.diffuse.contents = scene
        
        node.addChildNode(parentNode)
    }
    
    func track(_ key: String, _ node: SCNNode?) {
        guard let mappings = mappings else {
            return
        }
        
        var target: Mapping?
        for mapping in mappings {
            if (mapping.id == Int(key)) {
                target = mapping
                break
            }
        }
        
        DispatchQueue.main.async {
            if let mapping = target {
                if (mapping.trigger) {
                    self.bannerView.isHidden = true
                    self.bannerTriggerView.isHidden = false
//                    self.bannerTriggerLabel.text = "Create your profile now and collect \(mapping.points) points"
                    self.bannerTriggerLabel.text = "Register now and earn \(mapping.points) points!"
                    UserDefaults.standard.set(mapping.points, forKey: "triggerPoints")
                } else {
                    self.bannerView.isHidden = false
                    self.bannerTriggerView.isHidden = true
                    self.bannerLabel.text = "Learn more at www.dior.com"
                    UserDefaults.standard.set(mapping.points, forKey: "points")
                }
            }
        }
    }
    
    func untrack(_ key: String, _ node: SCNNode?) {
        guard let state = states[key] else {
            return
        }
        state.player?.pause()
        if (state.completed) {
            node?.removeFromParentNode()
            state.reset()
        }
        DispatchQueue.main.async {
            //            self.bannerView.isHidden = true
            //            self.bannerTriggerView.isHidden = true
        }
    }
    
    @IBAction func onBackButtonClick(_ sender: Any) {
        navigationController?.popViewController(animated: false)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor, let key = imageAnchor.referenceImage.name else {
            return
        }
        let targetNode = children(node, key: key)
        if (imageAnchor.isTracked && targetNode == nil) {
            append(node, imageAnchor, key)
        } else if (imageAnchor.isTracked && targetNode != nil) {
            track(key, targetNode)
        } else if (!imageAnchor.isTracked && targetNode != nil) {
            untrack(key, targetNode)
        }
    }

}
