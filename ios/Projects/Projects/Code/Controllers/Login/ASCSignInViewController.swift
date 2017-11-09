//
//  ASCSignInViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 6/1/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import Alamofire
import SkyFloatingLabelTextField
import IQKeyboardManagerSwift
import MBProgressHUD

enum ASCLoginType {
    case email
    case facebook
    case google
}

class ASCSignInViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Properties
    var portal: String?
    private let facebookSignInController = ASCFacebookSignInController()
    private let googleSignInController = ASCGoogleSignInController()
    
    @IBOutlet weak var emailField: SkyFloatingLabelTextField!
    @IBOutlet weak var passwordField: SkyFloatingLabelTextField!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var ssoButton: UIButton!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addressLabel?.text = portal
        
        if UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.portalLDAP) {
            emailField?.placeholder = NSLocalizedString("Login", comment: "")
        } else {
            emailField?.placeholder = NSLocalizedString("Email", comment: "")
        }
        passwordField?.placeholder = NSLocalizedString("Password", comment: "")
        
//        if #available(iOS 11.0, *) {
//            emailField?.textContentType = .username
//            passwordField?.textContentType = .password
//        }
        
        for field in [emailField, passwordField] {
            field?.titleFont = UIFont.systemFont(ofSize: 12)
            field?.lineHeight = UIDevice.screenPixel
            field?.selectedLineHeight = UIDevice.screenPixel * 2
            field?.titleFormatter = { $0.uppercased() }
            field?.placeholder = field?.placeholder?.uppercased()
            field?.placeholderFont = UIFont.systemFont(ofSize: 12)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(loginByCode(_:)), name: ASCConstants.Notifications.loginCode, object: nil)
        
        let ssoUrl = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.portalSSO) ?? ""
        
        if ssoUrl.length < 1 {
            ssoButton?.removeFromSuperview()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        IQKeyboardManager.sharedManager().enable = true
        IQKeyboardManager.sharedManager().enableAutoToolbar = true
        IQKeyboardManager.sharedManager().shouldShowToolbarPlaceholder = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        IQKeyboardManager.sharedManager().enable = false
        IQKeyboardManager.sharedManager().enableAutoToolbar = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Private
    
    private func valid(login: String) -> Bool {
        if login.length < 1 {
            emailField?.errorMessage = NSLocalizedString("Login is empty", comment: "")
            emailField?.shake()
            return false
        }
        
        return true
    }
    
    private func valid(email: String) -> Bool {
        if email.length < 1 {
            emailField?.errorMessage = NSLocalizedString("Email is empty", comment: "")
            emailField?.shake()
            return false
        }
        
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        
        if !emailTest.evaluate(with: email) {
            emailField?.errorMessage = NSLocalizedString("Email is not valid", comment: "")
            emailField?.shake()
            return false
        }
        
        return true
    }
    
    private func valid(password: String) -> Bool {
        if password.length < 1 {
            passwordField?.errorMessage = NSLocalizedString("Password is empty", comment: "")
            passwordField?.shake()
            return false
        }
        
        return true
    }
    
    private func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch let error {
            print("Error: Invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    @objc func loginByCode(_ notification: Notification) {
        if let options = notification.userInfo as? [String: String] {
            
            var type: ASCLoginType = .email
            
            if options["provider"] == "facebook" {
                type = .facebook
            }
            
            if options["provider"] == "google" {
                type = .google
            }
            
            let hud = MBProgressHUD.showTopMost()
            hud?.label.text = NSLocalizedString("Login", comment: "Caption of the process")
            
            self.login(by: type, options: options) { (success) in
                if success {
                    hud?.setSuccessState()
                    hud?.hide(animated: true, afterDelay: 2)
                    
                    NotificationCenter.default.post(name: ASCConstants.Notifications.loginCompleted, object: nil)
                    
                    self.dismiss(animated: true, completion: {
                        //
                    })
                } else {
                    hud?.hide(animated: true)
                }
            }
        }
    }
    
    private func login(by type: ASCLoginType, options: Parameters, completion: ((_ success: Bool) -> Void)? = nil) {
        guard var portalUrl = options["portal"] as? String else {
            completion?(false)
            return
        }
        
        let api             = ASCApi.shared
        let email           = options["userName"]
        let password        = options["password"]
        let facebookToken   = options["facebookToken"]
        let googleToken     = options["googleToken"]
        
        var apiRequest      = ASCApi.apiAuthentication
        var apiOptions: [String: String] = [:]
        
        portalUrl = portalUrl.lowercased()
        
        if type == .facebook {
            apiOptions["provider"] = "facebook"
            apiOptions["accessToken"] = facebookToken as? String
        } else if type == .google {
            apiOptions["provider"]  = "google"
            apiOptions["accessToken"] = googleToken as? String
        } else {
            apiOptions["provider"] = "email"
            apiOptions["userName"] = email as? String
            apiOptions["password"] = password as? String
        }
        
        apiOptions["portal"] = portalUrl
        
        if let code = options["code"] as? String {
            apiRequest = apiRequest + "/" + code
            apiOptions["code"] = code
        }
        
        var useProtocols = [String]()
        
        if matches(for: "^https?://", in: portalUrl).count < 1 {
            useProtocols += ["https://", "http://"]
        }
        
        func doLogin() {
            var baseUrl = portalUrl
            
            if useProtocols.count > 0 {
                baseUrl = useProtocols.first! + portalUrl
                useProtocols.removeFirst()
            }
            
            // Setup API manager
            api.baseUrl = baseUrl
            
            ASCApi.post(apiRequest, parameters: apiOptions) { (results, error, response) in
                if let results = results as? [String: Any] {
                    if let token = results["token"] as? String, token != "" {
                        // Set API token
                        api.token = token
                        
                        // Save auth info into user perfomances
                        UserDefaults.standard.set(baseUrl, forKey: ASCConstants.SettingsKeys.portalUrl)
                        UserDefaults.standard.set(token, forKey: ASCConstants.SettingsKeys.accessToken)

                        completion?(true)
                        
                        // Registration device into the portal
                        ASCApi.post(ASCApi.apiDeviceRegistration, parameters: ["type": 2], completion: { (_, _, _) in
                            // 2 - IOSDocuments
                        })
                    } else if (results["sms"] as? Bool)! {
                        MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                        completion?(false)
                        
                        if let phoneNoise = results["phoneNoise"] as? String {
                            apiOptions["phoneNoise"] = phoneNoise
                            
                            if let smsCodeViewController = self.storyboard?.instantiateViewController(withIdentifier: "SmsCodeViewController") as? ASCSMSCodeViewController {
                                smsCodeViewController.options = apiOptions
                                self.navigationController?.pushViewController(smsCodeViewController, animated: true)
                            }
                        } else {
                            if let phoneViewController = self.storyboard?.instantiateViewController(withIdentifier: "PhoneNumberViewController") as? ASCPhoneNumberViewController {
                                phoneViewController.options = apiOptions
                                self.navigationController?.pushViewController(phoneViewController, animated: true)
                            }
                        }
                    } else {
                        let alertController = UIAlertController.alert(
                            NSLocalizedString("Error", comment: ""),
                            message: String.localizedStringWithFormat("The %@ server is not available", baseUrl),
                            actions: []
                            ).okable()
                        self.present(alertController, animated: true, completion: nil)
                        
                        completion?(false)
                    }
                } else {
                    let errorInfo = ASCApi.errorInfo(by: response!)
                    let errorMessage = ASCApi.errorMessage(by: response!)
                    
                    print(errorMessage)
                    
                    if errorInfo == nil && useProtocols.count > 0 {
                        let alertController = UIAlertController.alert(
                            NSLocalizedString("Error", comment: ""),
                            message: String(format: "%@ %@", errorMessage, NSLocalizedString("Try to connect via another protocol?", comment: "")),
                            actions: [])
                            .okable() { _ in
                                doLogin()
                            }
                            .cancelable() { _ in
                                completion?(false)
                        }
                        
                        self.present(alertController, animated: true, completion: nil)
                    } else {
                        let alertController = UIAlertController.alert(
                            NSLocalizedString("Error", comment: ""),
                            message: errorMessage,
                            actions: [])
                            .okable() { _ in
                                completion?(false)
                        }
                        
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        }
        
        doLogin()
    }
        
    // MARK: - Text Field Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1
        
        if let nextResponder = textField.superview?.viewWithTag(nextTag) {
            nextResponder.becomeFirstResponder()
        } else {
            onEmailLogin(textField)            
            return true
        }
        
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let floatingLabelTextField = textField as? SkyFloatingLabelTextField {
            floatingLabelTextField.errorMessage = ""
        }
        return true
    }
    
    // MARK: - Actions
    
    @IBAction func onForgotPassword(_ sender: Any) {
        if let portal = portal, let portalUrl = URL(string: String(format: ASCConstants.Urls.apiForgetPassword, portal)) {
            if UIApplication.shared.canOpenURL(portalUrl) {
                UIApplication.shared.open(portalUrl, options: [:], completionHandler: nil)
            }
        }
    }
    
    @IBAction func onEmailLogin(_ sender: Any) {
        guard let portal = ASCApi.shared.baseUrl ?? portal?.trim() else {
            return
        }
        
        guard let email = emailField?.text?.trim() else {
            return
        }
        
        if UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.portalLDAP) {
            if !valid(login: email) {
                return
            }
        } else {
            if !valid(email: email) {
                return
            }
        }
        
        guard let password = passwordField?.text?.trim(), valid(password: password) else {
            return
        }
        
        view.endEditing(true)
        
        let parameters: Parameters = [
            "portal": portal,
            "userName": email,
            "password": password
        ]
        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Login", comment: "Caption of the process")
        
        self.login(by: .email, options: parameters) { (success) in
            if success {
                hud?.setSuccessState()
                hud?.hide(animated: true, afterDelay: 2)
                
                NotificationCenter.default.post(name: ASCConstants.Notifications.loginCompleted, object: nil)
                
                //                ASCAccessManager.shared.readUserInfo()
                
                // Handle registration push notification
                // id allowPush = [[NSUserDefaults standardUserDefaults] objectForKey:@"asc-allow-push"];
                // NSString * deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"asc-device-token"];
                //
                // if (allowPush && deviceToken) {
                //     if ([allowPush boolValue]) {
                //         [[TLApi sharedInstance] doPost:APIDeviceToken
                //             parameters:@{
                //                 @"type": @(2),
                //                 @"token": deviceToken
                //         }
                //         completion:nil];
                //     } else {
                //         [[TLApi sharedInstance] doDelete:APIDeviceToken
                //             parameters:@{
                //                 @"token": deviceToken
                //         }
                //         completion:nil];
                //
                //     }
                // }
                
                
                self.dismiss(animated: true, completion: nil)
            } else {
                hud?.hide(animated: true)
            }
        }
    }
    
    @IBAction func onFacebookLogin(_ sender: UIButton) {
        view.endEditing(true)
        
        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Login", comment: "Caption of the process")
        
        facebookSignInController.signIn(controller: self) { (token, error) in
            if let accessToken = token {
                let parameters: Parameters = [
                    "portal": self.portal ?? "",
                    "facebookToken": accessToken
                ]
                
                self.login(by: .facebook, options: parameters) { (success) in
                    if success {
                        hud?.setSuccessState()
                        hud?.hide(animated: true, afterDelay: 2)
                        
                        NotificationCenter.default.post(name: ASCConstants.Notifications.loginCompleted, object: nil)
                        
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        hud?.hide(animated: true)
                    }
                }
            } else {
                hud?.hide(animated: true)
                
                if let _ = error {
                    UIAlertController.showError(in: self, message: NSLocalizedString("Unable to get information about the user.", comment: ""))
                }
            }
        }
    }
    
    @IBAction func onGoogleLogin(_ sender: UIButton) {
        view.endEditing(true)
        
        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Login", comment: "Caption of the process")
        
        googleSignInController.signIn(controller: self) { (token, error) in
            if let accessToken = token {
                let parameters: Parameters = [
                    "portal": self.portal ?? "",
                    "googleToken": accessToken
                ]
                
                self.login(by: .google, options: parameters) { (success) in
                    if success {
                        hud?.setSuccessState()
                        hud?.hide(animated: true, afterDelay: 2)
                        
                        NotificationCenter.default.post(name: ASCConstants.Notifications.loginCompleted, object: nil)
                        
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        hud?.hide(animated: true)
                    }
                }
            } else {
                hud?.hide(animated: true)
                
                if let _ = error {
                    UIAlertController.showError(in: self, message: NSLocalizedString("Unable to get information about the user.", comment: ""))
                }
            }
        }
    }
    
    @IBAction func onSSOLogin(_ sender: UIButton) {
        view.endEditing(true)
        
        if let ssoNavigationController = storyboard?.instantiateViewController(withIdentifier: "ASCSSOSignInNavigationController") as? UINavigationController {
            present(ssoNavigationController, animated: true, completion: { [weak self] in
                guard let strongSelf = self else { return }
                
                if let ssoViewController = ssoNavigationController.topViewController as? ASCSSOSignInController {
                    ssoViewController.signIn(ssoUrl: UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.portalSSO) ?? "", handler: { token, error in
                        if let token = token, token.length > 0 {
                            if let hud = MBProgressHUD.showTopMost() {
                                hud.label.text = NSLocalizedString("Login", comment: "Caption of the process")
                                hud.setSuccessState()
                                hud.hide(animated: true, afterDelay: 2)
                            }
                            
                            ASCApi.shared.token = token
                            
                            // Save auth info into user perfomances
                            UserDefaults.standard.set(ASCApi.shared.baseUrl, forKey: ASCConstants.SettingsKeys.portalUrl)
                            UserDefaults.standard.set(token, forKey: ASCConstants.SettingsKeys.accessToken)
                            
                            // Registration device into the portal
                            ASCApi.post(ASCApi.apiDeviceRegistration, parameters: ["type": 2], completion: { (_, _, _) in
                                // 2 - IOSDocuments
                            })
                            
                            NotificationCenter.default.post(name: ASCConstants.Notifications.loginCompleted, object: nil)
                            
                            strongSelf.dismiss(animated: true, completion: nil)
                        }
                    })
                }
            })
        }
    }
    
}
