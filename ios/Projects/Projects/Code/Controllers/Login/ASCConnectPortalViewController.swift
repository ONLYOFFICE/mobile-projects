//
//  ASCConnectPortalViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 6/1/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField
import IQKeyboardManagerSwift
import Alamofire
import MBProgressHUD

class ASCConnectPortalViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Properties
    
    @IBOutlet weak var createPortalButton: UIButton!
    @IBOutlet weak var addressField: SkyFloatingLabelTextField!
    @IBOutlet weak var infoLabel: UILabel!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addressField?.titleFont = UIFont.systemFont(ofSize: 12)
        addressField?.lineHeight = UIDevice.screenPixel
        addressField?.selectedLineHeight = UIDevice.screenPixel * 2
        addressField?.titleFormatter = { $0.uppercased() }
        addressField?.placeholder = NSLocalizedString("Enter Portal Address", comment: "").uppercased()
        addressField?.placeholderFont = UIFont.systemFont(ofSize: 12)
        
        // Decorate info label
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        paragraphStyle.alignment = .center
        let attributedString = NSMutableAttributedString(string: infoLabel?.text ?? "")
        attributedString.addAttribute(.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))
        
        infoLabel?.attributedText = attributedString
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        if let navigationController = navigationController {
            navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController.navigationBar.isTranslucent = true
            navigationController.navigationBar.shadowImage = UIImage()
            
            if navigationController.viewControllers.count < 2 {
                navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(onClose(_:)))
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        navigationController?.setNavigationBarHidden(false, animated: animated)
        view.endEditing(true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Private
    
    private func ipAddress(of host: String) -> String? {
        let host = CFHostCreateWithName(nil, host as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)
        var success: DarwinBoolean = false
        if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray?,
            let theAddress = addresses.firstObject as? NSData {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(theAddress.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(theAddress.length),
                           &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                let numAddress = String(cString: hostname)
                print(numAddress)
                
                return numAddress
            }
        }
        
        return nil
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
    
    private func validatePortal(validation: @escaping (Bool, String?, [String: Any]?)->()) {
        guard let portalUrl = addressField?.text?.trim() else {
            validation(false, NSLocalizedString("Address is empty", comment: ""), nil)
            return
        }
        
        if portalUrl.length < 1 {
            validation(false, NSLocalizedString("Address is empty", comment: ""), nil)
            return
        }
        
        // Cleanup portal capabilities
        UserDefaults.standard.set(false, forKey: ASCConstants.SettingsKeys.portalLDAP)
        UserDefaults.standard.set("", forKey: ASCConstants.SettingsKeys.portalSSO)
        UserDefaults.standard.set("", forKey: ASCConstants.SettingsKeys.portalSSOLabel)
        
        let api = ASCApi.shared
        
        var useProtocols = [String]()
        
        if matches(for: "^https?://", in: portalUrl).count < 1 {
            useProtocols += ["https://", "http://"]
        }
        
        func checkPortal() {
            var baseUrl = portalUrl
            
            if useProtocols.count > 0 {
                baseUrl = useProtocols.first! + portalUrl
                useProtocols.removeFirst()
            }
            
            // Setup API manager
            api.baseUrl = baseUrl
            
            ASCApi.get(ASCApi.apiCapabilities) { [weak self] results, error, response in
                guard let strongSelf = self else { return }
                
                if let results = results as? [String: Any] {
                    // Setup portal capabilities
                    UserDefaults.standard.set(results["ldapEnabled"], forKey: ASCConstants.SettingsKeys.portalLDAP)
                    UserDefaults.standard.set(results["ssoUrl"], forKey: ASCConstants.SettingsKeys.portalSSO)
                    UserDefaults.standard.set(results["ssoLabel"], forKey: ASCConstants.SettingsKeys.portalSSOLabel)
                    
                    validation(true, nil, results)
                } else {
                    let errorInfo = ASCApi.errorInfo(by: response!)
                    let errorMessage = ASCApi.errorMessage(by: response!)
                    
                    debugPrint(errorMessage)
                    
                    if errorInfo == nil && useProtocols.count > 0 {
                        let alertController = UIAlertController.alert(
                            NSLocalizedString("Error", comment: ""),
                            message: String(format: "%@ %@", errorMessage, NSLocalizedString("Try to connect via another protocol?", comment: "")),
                            actions: [])
                            .okable() { _ in
                                checkPortal()
                            }
                            .cancelable() { _ in
                                validation(false, nil, nil)
                        }
                        
                        strongSelf.present(alertController, animated: true, completion: nil)
                    } else {
                        api.baseUrl = nil
                        validation(true, NSLocalizedString("Failed to check portal availability.", comment: ""), nil)
                    }
                }
            }
        }
        
        checkPortal()
    }
    
    private func showSignIn() {
        if let signinViewController = storyboard?.instantiateViewController(withIdentifier: "SignInViewController") as? ASCSignInViewController {
            signinViewController.portal = addressField?.text?.trim()
            navigationController?.pushViewController(signinViewController, animated: true)
        }
    }
    
    // MARK: - UITextField Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onContinue(textField)
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let floatingLabelTextField = textField as? SkyFloatingLabelTextField {
            floatingLabelTextField.errorMessage = ""
        }
        return true
    }
    
    // MARK: - Actions
    
    @IBAction func onClose(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onContinue(_ sender: Any) {
        let hud = MBProgressHUD.showTopMost()
        hud?.labelText = NSLocalizedString("Connecting", comment: "Caption of the process")
        
        view.endEditing(true)
        
        validatePortal { [weak self] sussess, error, capabilities in
            hud?.hide(true)
            
            guard let strongSelf = self else { return }
            if !sussess {
                strongSelf.addressField?.shake()
                strongSelf.addressField?.errorMessage = error ?? NSLocalizedString("The portal address is invalid", comment: "")
            } else if let error = error {
                let alertController = UIAlertController(title: NSLocalizedString("Error", comment:""), message: error, preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Continue anyway", comment: ""), style: .default, handler: { action in
                    strongSelf.showSignIn()
                }))
                
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { action in
                    //
                }))
                
                alertController.view.tintColor = strongSelf.view.tintColor
                strongSelf.present(alertController, animated: true, completion: nil)
            } else {
                strongSelf.addressField?.errorMessage = nil
                strongSelf.showSignIn()
            }
        }
    }
    

}
