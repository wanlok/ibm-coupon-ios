//
//  RegistrationViewController.swift
//  coupon
//
//  Created by WAN Tung Lok on 20/11/2019.
//  Copyright © 2019 IBM. All rights reserved.
//

import UIKit

class RegistrationViewController: BaseViewController, UITextFieldDelegate {
    
    @IBOutlet weak var topLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var firstNameTextField: UITextField!
    
    @IBOutlet weak var lastNameTextField: UITextField!
    
    @IBOutlet weak var phoneTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var refererCodeTextField: UITextField!
    
    @IBOutlet weak var loadingView: UIView!
    
    @IBAction func onCloseButtonClick(_ sender: Any) {
        navigationController?.popViewController(animated: false)
    }
    
    var keyboardHeight: CGFloat?
    
    var webService: WebService?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        phoneTextField.delegate = self
        emailTextField.delegate = self
        refererCodeTextField.delegate = self
        
        webService = WebService()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (UserDefaults.standard.bool(forKey: "triggered")) {
            print("Previously triggered")
            UserDefaults.standard.set(0, forKey: "points")
        }
    }
    
    func updateBottomLayoutConstraint(_ keyboardHeight: CGFloat?) {
        guard let keyboardHeight = keyboardHeight else {
            return
        }
        if (firstNameTextField.isEditing) {
            
        } else if (lastNameTextField.isEditing) {
//            bottomLayoutConstraint.constant = keyboardHeight - 56 - 16 - 56 - 16 - 56
        } else if (phoneTextField.isEditing) {
//            bottomLayoutConstraint.constant = keyboardHeight - 56 - 16 - 56
        } else if (emailTextField.isEditing) {
//            bottomLayoutConstraint.constant = keyboardHeight - 56
        } else if (refererCodeTextField.isEditing) {
            if (UIScreen.main.nativeBounds.height <= 1334) {
                topLayoutConstraint.constant = -37
            }
        }
        self.keyboardHeight = keyboardHeight
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            updateBottomLayoutConstraint(keyboardHeight)
        }
    }
    
    @IBAction func onRegisterButtonClick(_ sender: Any) {
        guard let webService = webService, let firstName = firstNameTextField.text, let lastName = lastNameTextField.text, let phone = phoneTextField.text, let email = emailTextField.text, let refererCode = refererCodeTextField.text else {
            return
        }
        loadingView.isHidden = false
        let grantType = "password"
        let clientId = "3MVG9G9pzCUSkzZsCdLE1sGkG4HWojFmMVDpwExyLJVrizRF7bOKIvYrzde3r.iHJjVp15whsWMv85sf7YQbs"
        let clientSecret = "A3A650047CDA0A11972F7599B341D78AC5652B3F7927CB442381FD15286F6754"
        let username = "anthliu@hk.ibm.com.demo"
        let password = "Salesforce1d24oaaudYAq7q6mEjaC9fbPnv"
        let params = "grant_type=\(grantType)&client_id=\(clientId)&client_secret=\(clientSecret)&username=\(username)&password=\(password)"
        let accountId = "0012v00002h8dTqAAI"
        webService.postJSONData("https://login.salesforce.com/services/oauth2/token", params: params) { (ok, data) in
            print("One")
            guard let data = data, let dict = webService.toJSONObject(data), let a = dict["access_token"], let accessToken = a as? String else {
                return
            }
            let jsonParams1 = ["FirstName": firstName, "LastName": lastName, "Email": email, "accountId": accountId, "Referer_Code__c": refererCode]
            print(jsonParams1)
            webService.jsonPostJSONData("https://aacrm-demo-dev-ed.my.salesforce.com/services/data/v45.0/sobjects/Contact", params: jsonParams1, token: accessToken) { (ok, data) in
                print("Two")
                guard let data = data else {
                    return
                }
                if let dict = webService.toJSONObject(data), let a = dict["id"], let contact = a {
                    let points: Int
                    if (UserDefaults.standard.bool(forKey: "triggered")) {
                        points = UserDefaults.standard.integer(forKey: "triggerPoints")
                    } else {
                        points = UserDefaults.standard.integer(forKey: "points")
                    }
                    let name = "AR App Enrollment"
                    let transactionType = "E-Commerce"
                    let status = "Confirmed"
                    let transactionAmount = points
                    let recordTypeId = "0122v000001prjoAAA"
                    
                    let jsonParams2 = ["Contact__c": contact, "Name": name, "Transaction_Type__c": transactionType, "Status__c": status, "Transaction_Amount__c": transactionAmount, "recordTypeId": recordTypeId]
                    webService.jsonPostJSONData("https://aacrm-demo-dev-ed.my.salesforce.com/services/data/v45.0/sobjects/Transaction__c", params: jsonParams2, token: accessToken) { (ok, data) in
                        print("Three")
                        guard let data = data else {
                            return
                        }
                        print(webService.toJSONObject(data))
                        DispatchQueue.main.async {
                            self.loadingView.isHidden = true
                            self.navigationController?.popViewController(animated: false)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.loadingView.isHidden = true
                        self.navigationController?.popViewController(animated: false)
                    }
                }
            }
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateBottomLayoutConstraint(keyboardHeight)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        topLayoutConstraint.constant = 16
    }
}
