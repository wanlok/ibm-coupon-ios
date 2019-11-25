//
//  BaseViewController.swift
//  coupon
//
//  Created by WAN Tung Lok on 17/11/2019.
//  Copyright © 2019 IBM. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
