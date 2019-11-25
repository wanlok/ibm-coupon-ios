//
//  LandingViewController.swift
//  coupon
//
//  Created by WAN Tung Lok on 17/11/2019.
//  Copyright © 2019 IBM. All rights reserved.
//

import UIKit

class LandingViewController: BaseViewController {
    
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var scanButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerButton.imageView?.contentMode = .scaleAspectFit
        scanButton.imageView?.contentMode = .scaleAspectFit
        
        registerButton.layer.cornerRadius = 16
        scanButton.layer.cornerRadius = 16
    }
    
    @IBAction func onRegisterButtonClick(_ sender: Any) {
        UserDefaults.standard.set(false, forKey: "triggered")
        navigationController?.pushViewController(RegistrationViewController(), animated: false)
    }
    
    @IBAction func onScanButtonClick(_ sender: Any) {
        navigationController?.pushViewController(CameraViewController(), animated: false)
    }
}
