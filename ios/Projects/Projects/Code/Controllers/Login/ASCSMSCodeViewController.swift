//
//  ASCSMSCodeViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/11/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import MBProgressHUD

class ASCSMSCodeViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Properties
    
    @IBOutlet weak var codeField: UITextField!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var sendSmsLabel: UILabel!
    
    var phoneNumber: String = "" {
        didSet {
            infoLabel?.text = String(format:NSLocalizedString("We have sent you an SMS with a code to the number %@", comment: ""), phoneNumber)
        }
    }
    var options: [String: String] = [:]
    private let codeLength: Int = 6
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if UIDevice.phone {
            if UIDevice.greatOfInches(.inches47) {
                topConstraint.constant = 20
            } else {
                topConstraint.constant = 0
            }
        }
        
        codeField?.delegate = self
        underline(textField: codeField!)
        codeField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapFunction))
        sendSmsLabel.isUserInteractionEnabled = true
        sendSmsLabel.addGestureRecognizer(tapGesture)
        
        if let phoneNoise = options["phoneNoise"] {
            infoLabel?.text = String(format:NSLocalizedString("We have sent you an SMS with a code to the number %@", comment: ""), phoneNoise)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.shadowImage = UIImage()
        
        codeField?.becomeFirstResponder()
    }
    
    @objc func tapFunction(sender: UITapGestureRecognizer) {
        sendSmsLabel.alpha = 0.5
        
        UIView.animate(withDuration: 0.6) {
            self.sendSmsLabel.alpha = 1
        }
        
        resendCode()
    }
    
    // MARK: - Private
    
    private func underline(textField: UITextField) {
        let border = CALayer()
        let width = UIDevice.screenPixel
        border.borderColor = ASCConstants.Colors.lightGrey.cgColor
        border.frame = CGRect(x: 0, y: textField.frame.size.height - width, width: textField.frame.size.width, height: textField.frame.size.height)
        border.borderWidth = width
        textField.layer.addSublayer(border)
        textField.layer.masksToBounds = true
    }
    
    private func resendCode() {
        let hud = MBProgressHUD.showTopMost()
        ASCApi.post(ASCApi.apiAuthenticationCode, parameters: options) { (results, error, response) in
            hud?.hide(true)
            
            if error != nil {
                UIAlertController.showError(in: self, message: ASCApi.errorMessage(by: response!))
                print(error!)
            }
        }
    }
    
    private func login(with code: String) {
        options["code"] = code
        NotificationCenter.default.post(name: ASCConstants.Notifications.loginCode, object: nil, userInfo: options)
    }
    
    // MARK: - UITextField Delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentCharacterCount = textField.text?.characters.count ?? 0
        
        if (range.length + range.location > currentCharacterCount){
            return false
        }
        
        let newLength = currentCharacterCount + string.characters.count - range.length
        
        return newLength <= codeLength
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField == codeField, let fieldText = textField.text {
            let code = fieldText.trim().substring(to: codeLength)
            
            if code.length == codeLength {
                login(with: code)
            }
        }
    }

}
