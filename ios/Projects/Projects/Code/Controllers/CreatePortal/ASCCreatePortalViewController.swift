//
//  ASCCreatePortalViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/29/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import MBProgressHUD
import Alamofire
import SkyFloatingLabelTextField

class ASCCreatePortalViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Properties
    var portal: String?
    var firstName: String?
    var lastName: String?
    var email: String?
    
    @IBOutlet weak var portalField: ParkedTextField!
    @IBOutlet weak var firstNameField: SkyFloatingLabelTextField!
    @IBOutlet weak var lastNameField: SkyFloatingLabelTextField!
    @IBOutlet weak var emailField: SkyFloatingLabelTextField!
    @IBOutlet weak var passwordOneField: SkyFloatingLabelTextField!
    @IBOutlet weak var passwordTwoField: SkyFloatingLabelTextField!
    @IBOutlet weak var termsLabel: UILabel!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        portalField?.parkedText = "." + domain(by: Locale.current.regionCode ?? "US")
        portalField?.selectedTitle = NSLocalizedString("Portal Address", comment: "")
        portalField?.title = NSLocalizedString("Portal Address", comment: "")
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapTerms))
        termsLabel?.isUserInteractionEnabled = true
        termsLabel?.addGestureRecognizer(tapGesture)
        
        for field in [portalField, firstNameField, lastNameField, emailField, passwordOneField, passwordTwoField] {
            field?.titleFont = UIFont.systemFont(ofSize: 12)
            field?.lineHeight = UIDevice.screenPixel
            field?.selectedLineHeight = UIDevice.screenPixel * 2
            field?.titleFormatter = { $0.uppercased() }
            field?.placeholder = field?.placeholder?.uppercased()
            field?.placeholderFont = UIFont.systemFont(ofSize: 12)
        }
        
        if UIDevice.pad {
            topConstraint?.constant = 100
        }
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @objc func tapTerms(sender: UITapGestureRecognizer) {
        termsLabel?.alpha = 0.5
        
        UIView.animate(withDuration: 0.6) {
            self.termsLabel?.alpha = 1
        }
        
        if let url = URL(string: "https://www.onlyoffice.com/legalterms.aspx"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    // MARK: - Private

    private func valid(portal: String) -> Bool {
        if portal.length < 1 {
            portalField?.errorMessage = NSLocalizedString("Account name is empty", comment: "")
            portalField?.shake()
            return false
        }
        
        // The account name must be between 6 and 50 characters long.
        if !(6...50 ~= portal.characters.count) {
            portalField?.errorMessage = NSLocalizedString("Account name is not valid", comment: "")
            portalField?.shake()
            showError(NSLocalizedString("The account name must be between 6 and 50 characters long", comment: ""))
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
    
    private func valid(name: String) -> Bool {
        if name.length < 1 {
            return false
        }
        
        return true
    }
    
    private func valid(password: String) -> Bool {
        if password.length < 1 {
            return false
        }
        
        return true
    }
    
    private func showNextStep() {
        IQKeyboardManager.sharedManager().resignFirstResponder()
        
        guard let portal = portalField?.typedText.trim(), valid(portal: portal) else {
            return
        }
        
        guard let firstName = firstNameField?.text?.trim(), valid(name: firstName) else {
            firstNameField?.errorMessage = NSLocalizedString("Name is empty", comment: "")
            firstNameField?.shake()
            return
        }
        
        guard let lastName = lastNameField?.text?.trim(), valid(name: lastName) else {
            lastNameField?.errorMessage = NSLocalizedString("Name is empty", comment: "")
            lastNameField?.shake()
            return
        }
        
        guard let email = emailField?.text?.trim(), valid(email: email) else {
            emailField?.shake()
            return
        }
        
        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Validation", comment: "Caption of the process")
        
        let baseApi = String(format: ASCConstants.Urls.apiSystemUrl, domain(by: Locale.current.regionCode ?? "US"))
        let requestUrl = baseApi + "/" + ASCConstants.Urls.apiValidatePortalName
        let params: Parameters = [
            "portalName": portal
        ]
        
        Alamofire.request(requestUrl, method: .post, parameters: params)
            .validate()
            .responseJSON { response in
                DispatchQueue.main.async(execute: {
                    hud?.hide(animated: true)
                    
                    switch response.result {
                    case .success(let responseJson):
                        if let responseJson = responseJson as? [String: Any] {
                            if let _ = responseJson["errors"], let errors = responseJson["errors"] as? [String] {
                                if let errorType = errors.first {
                                    switch errorType {
                                    case "tooShortError":
                                        self.showError(NSLocalizedString("The portal name must be between 6 and 50 characters long", comment: ""))
                                        break
                                    case "portalNameExist":
                                        self.showError(NSLocalizedString("We are sorry, this portal name is already taken", comment: ""))
                                        break
                                    case "portalNameIncorrect":
                                        self.showError(NSLocalizedString("Incorrect portal address", comment: ""))
                                        break
                                    default:
                                        self.showError(NSLocalizedString("Failed to check the name of the portal", comment: ""))
                                    }
                                }
                            } else {
                                if let portalViewController = self.storyboard?.instantiateViewController(withIdentifier: "createPortalStepTwoController") as? ASCCreatePortalViewController {
                                    IQKeyboardManager.sharedManager().enable = false
                                    
                                    portalViewController.portal = portal
                                    portalViewController.firstName = firstName
                                    portalViewController.lastName = lastName
                                    portalViewController.email = email
                                    
                                    self.navigationController?.pushViewController(portalViewController, animated: true)
                                }
                            }
                        }
                    case .failure(let error):
                        debugPrint(error)
                        self.showError(error.localizedDescription)
                    }
                })
        }
    }
    
    private func createPortal() {
        IQKeyboardManager.sharedManager().resignFirstResponder()
        
        guard let passwordOne = passwordOneField?.text?.trim(), valid(password: passwordOne) else {
            passwordOneField?.errorMessage = NSLocalizedString("Password is empty", comment: "")
            passwordOneField?.shake()
            return
        }
        
        guard let passwordTwo = passwordTwoField?.text?.trim(), valid(password: passwordTwo) else {
            passwordTwoField?.errorMessage = NSLocalizedString("Password is empty", comment: "")
            passwordTwoField?.shake()
            return
        }
        
        if passwordOne != passwordTwo {
            passwordTwoField?.errorMessage = NSLocalizedString("Passwords do not match", comment: "")
            passwordTwoField?.shake()
            return
        }
        
        guard let firstName = firstName else {
            return
        }
        
        guard let lastName = lastName else {
            return
        }
        
        guard let email = email else {
            return
        }
        
        guard let language = Locale.preferredLanguages.first else {
            return
        }
        
        guard let portalName = portal else {
            return
        }
        
        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Registration", comment: "")
        
        let baseApi = String(format: ASCConstants.Urls.apiSystemUrl, domain(by: Locale.current.regionCode ?? "US"))
        let requestUrl = baseApi + "/" + ASCConstants.Urls.apiRegistrationPortal
        let params: Parameters = [
            "firstName"      : firstName,
            "lastName"       : lastName,
            "email"          : email,
            "phone"          : "",
            "portalName"     : portalName,
            "partnerId"      : "",
            "industry"       : 0,
            "timeZoneName"   : TimeZone.current.identifier,
            "language"       : language,
            "password"       : passwordOne
        ]
        
        Alamofire.request(requestUrl, method: .post, parameters: params)
            .validate()
            .responseJSON { response in
                DispatchQueue.main.async(execute: {
                    hud?.hide(animated: true)
                    
                    switch response.result {
                    case .success(let responseJson):
                        if let responseJson = responseJson as? [String: Any] {
                            if let _ = responseJson["errors"], let errors = responseJson["errors"] as? [String] {
                                if let errorType = errors.first {
                                    switch errorType {
                                    case "passPolicyError":
                                        self.showError(NSLocalizedString("The password is incorrect. It must contain 6 characters", comment: ""))
                                        break
                                    default:
                                        self.showError(String(format: NSLocalizedString("Сould not create a portal.\nError code - %@", comment: ""), errorType))
                                    }
                                }
                            } else {
                                if let tenant = responseJson["tenant"] as? [String: Any], let domain = tenant["tenantDomain"] as? String {
                                    self.login(address: domain)
                                } else {
                                    self.showError(NSLocalizedString("Unable to get information about the portal", comment: ""))
                                }
                            }
                        }
                    case .failure(let error):
                        debugPrint(error)
                        self.showError(error.localizedDescription)
                    }
                })
        }
    }

    private func login(address: String) {
        guard let login = email else {
            return
        }
        
        guard let password = passwordOneField?.text?.trim() else {
            return
        }
        
        let api = ASCApi.shared
        let baseUrl = "https://" + address
        
        let hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Login", comment: "Caption of the process")
        
        api.baseUrl = baseUrl
        
        let parameters: Parameters = [
            "provider": "email",
            "userName": login,
            "password": password
        ]
        
        ASCApi.post(ASCApi.apiAuthentication, parameters: parameters) { (results, error, response) in
            if let results = results as? [String: Any] {
                if let token = results["token"] as? String, token != "" {
                    // Set API token
                    api.token = token
                    
                    // Save auth info into user perfomances
                    UserDefaults.standard.set(baseUrl, forKey: ASCConstants.SettingsKeys.portalUrl)
                    UserDefaults.standard.set(token, forKey: ASCConstants.SettingsKeys.accessToken)
                    
                    // Registration device into the portal
                    ASCApi.post(ASCApi.apiDeviceRegistration, parameters: ["type": 2], completion: { (_, _, _) in
                        // 2 - IOSDocuments
                    })
                    
                    hud?.setSuccessState()
                    hud?.hide(animated: true, afterDelay: 2)

                    NotificationCenter.default.post(name: ASCConstants.Notifications.loginCompleted, object: nil)
         
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                hud?.hide(animated: true)
                
                let errorMessage = ASCApi.errorMessage(by: response!)
                
                print(errorMessage)
                self.showError(errorMessage)
            }
        }

    }
    
    private func showError(_ message: String) {
        UIAlertController.showError(in: self, message: message)
    }
    
    // MARK: - Actions
    
    @IBAction func onFinalStep(_ sender: UIButton) {
        showNextStep()
    }
    
    @IBAction func onCreate(_ sender: UIButton) {
        createPortal()
    }
    
    // MARK: - Text Field Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1
        
        if let nextResponder = textField.superview?.viewWithTag(nextTag) {
            nextResponder.becomeFirstResponder()
        } else {
            if restorationIdentifier == "createPortalStepOneController" {
                showNextStep()
            } else {
                createPortal()
            }
            
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
}

extension ASCCreatePortalViewController {
    func domain(by regin: String) -> String {        
        let domainRegion: [String: String] = [
            "EU": "onlyoffice.eu",
            "AX": "onlyoffice.eu",
            "AF": "onlyoffice.sg",
            "AL": "onlyoffice.eu",
            "DZ": "onlyoffice.eu",
            "AS": "onlyoffice.sg",
            "AD": "onlyoffice.eu",
            "AO": "onlyoffice.eu",
            "AI": "onlyoffice.com",
            "AQ": "onlyoffice.sg",
            "AG": "onlyoffice.com",
            "AR": "onlyoffice.com",
            "AM": "onlyoffice.eu",
            "AW": "onlyoffice.com",
            "AU": "onlyoffice.sg",
            "AT": "onlyoffice.eu",
            "AZ": "onlyoffice.eu",
            "BS": "onlyoffice.com",
            "BH": "onlyoffice.eu",
            "BD": "onlyoffice.sg",
            "BB": "onlyoffice.com",
            "BY": "onlyoffice.eu",
            "BE": "onlyoffice.eu",
            "BZ": "onlyoffice.com",
            "BJ": "onlyoffice.eu",
            "BM": "onlyoffice.com",
            "BT": "onlyoffice.sg",
            "BO": "onlyoffice.com",
            "BA": "onlyoffice.eu",
            "BW": "onlyoffice.eu",
            "BV": "onlyoffice.com",
            "BR": "onlyoffice.com",
            "IO": "onlyoffice.sg",
            "BN": "onlyoffice.sg",
            "BG": "onlyoffice.eu",
            "BF": "onlyoffice.eu",
            "BI": "onlyoffice.eu",
            "KH": "onlyoffice.sg",
            "CM": "onlyoffice.eu",
            "CA": "onlyoffice.com",
            "CV": "onlyoffice.eu",
            "KY": "onlyoffice.com",
            "CF": "onlyoffice.eu",
            "TD": "onlyoffice.eu",
            "CL": "onlyoffice.com",
            "CN": "onlyoffice.sg",
            "CX": "onlyoffice.sg",
            "CC": "onlyoffice.sg",
            "CO": "onlyoffice.com",
            "KM": "onlyoffice.eu",
            "CD": "onlyoffice.eu",
            "CG": "onlyoffice.eu",
            "CK": "onlyoffice.sg",
            "CR": "onlyoffice.com",
            "CI": "onlyoffice.com",
            "HR": "onlyoffice.eu",
            "CU": "onlyoffice.com",
            "CY": "onlyoffice.eu",
            "CZ": "onlyoffice.eu",
            "DK": "onlyoffice.eu",
            "DJ": "onlyoffice.eu",
            "DM": "onlyoffice.com",
            "DO": "onlyoffice.com",
            "EC": "onlyoffice.com",
            "EG": "onlyoffice.eu",
            "SV": "onlyoffice.com",
            "GQ": "onlyoffice.eu",
            "ER": "onlyoffice.eu",
            "EE": "onlyoffice.eu",
            "ET": "onlyoffice.eu",
            "FK": "onlyoffice.com",
            "FO": "onlyoffice.eu",
            "FJ": "onlyoffice.sg",
            "FI": "onlyoffice.eu",
            "FR": "onlyoffice.eu",
            "GF": "onlyoffice.com",
            "PF": "onlyoffice.sg",
            "TF": "onlyoffice.eu",
            "GA": "onlyoffice.eu",
            "GM": "onlyoffice.eu",
            "GE": "onlyoffice.eu",
            "DE": "onlyoffice.eu",
            "GH": "onlyoffice.eu",
            "GI": "onlyoffice.eu",
            "GR": "onlyoffice.eu",
            "GL": "onlyoffice.eu",
            "GD": "onlyoffice.com",
            "GP": "onlyoffice.com",
            "GU": "onlyoffice.sg",
            "GT": "onlyoffice.com",
            "GN": "onlyoffice.eu",
            "GW": "onlyoffice.eu",
            "GY": "onlyoffice.com",
            "HT": "onlyoffice.com",
            "HM": "onlyoffice.com",
            "HN": "onlyoffice.com",
            "HK": "onlyoffice.sg",
            "HU": "onlyoffice.eu",
            "IS": "onlyoffice.eu",
            "IN": "onlyoffice.sg",
            "ID": "onlyoffice.sg",
            "IR": "onlyoffice.eu",
            "IQ": "onlyoffice.eu",
            "IE": "onlyoffice.eu",
            "IL": "onlyoffice.eu",
            "IT": "onlyoffice.eu",
            "JM": "onlyoffice.com",
            "JP": "onlyoffice.sg",
            "JO": "onlyoffice.eu",
            "KZ": "onlyoffice.eu",
            "KE": "onlyoffice.eu",
            "KI": "onlyoffice.sg",
            "KP": "onlyoffice.sg",
            "KR": "onlyoffice.sg",
            "KW": "onlyoffice.eu",
            "KG": "onlyoffice.sg",
            "LA": "onlyoffice.sg",
            "LV": "onlyoffice.eu",
            "LB": "onlyoffice.eu",
            "LS": "onlyoffice.eu",
            "LR": "onlyoffice.eu",
            "LY": "onlyoffice.eu",
            "LI": "onlyoffice.eu",
            "LT": "onlyoffice.eu",
            "LU": "onlyoffice.eu",
            "MO": "onlyoffice.sg",
            "MK": "onlyoffice.eu",
            "MG": "onlyoffice.eu",
            "MW": "onlyoffice.eu",
            "MY": "onlyoffice.sg",
            "MV": "onlyoffice.sg",
            "ML": "onlyoffice.eu",
            "MT": "onlyoffice.eu",
            "MH": "onlyoffice.sg",
            "MQ": "onlyoffice.com",
            "MR": "onlyoffice.eu",
            "MU": "onlyoffice.eu",
            "YT": "onlyoffice.eu",
            "MX": "onlyoffice.com",
            "FM": "onlyoffice.sg",
            "MD": "onlyoffice.eu",
            "MC": "onlyoffice.eu",
            "MN": "onlyoffice.sg",
            "MS": "onlyoffice.com",
            "MA": "onlyoffice.eu",
            "MZ": "onlyoffice.eu",
            "MM": "onlyoffice.sg",
            "NA": "onlyoffice.eu",
            "NR": "onlyoffice.sg",
            "NP": "onlyoffice.sg",
            "NL": "onlyoffice.eu",
            "AN": "onlyoffice.com",
            "NC": "onlyoffice.sg",
            "NZ": "onlyoffice.sg",
            "NI": "onlyoffice.com",
            "NE": "onlyoffice.eu",
            "NG": "onlyoffice.eu",
            "NU": "onlyoffice.sg",
            "NF": "onlyoffice.sg",
            "MP": "onlyoffice.sg",
            "NO": "onlyoffice.eu",
            "OM": "onlyoffice.eu",
            "PK": "onlyoffice.sg",
            "PW": "onlyoffice.sg",
            "PS": "onlyoffice.eu",
            "PA": "onlyoffice.com",
            "PG": "onlyoffice.sg",
            "PY": "onlyoffice.com",
            "PE": "onlyoffice.com",
            "PH": "onlyoffice.sg",
            "PN": "onlyoffice.com",
            "PL": "onlyoffice.eu",
            "PT": "onlyoffice.eu",
            "PR": "onlyoffice.com",
            "QA": "onlyoffice.eu",
            "RE": "onlyoffice.eu",
            "RO": "onlyoffice.eu",
            "RU": "onlyoffice.eu",
            "RW": "onlyoffice.eu",
            "SH": "onlyoffice.eu",
            "KN": "onlyoffice.com",
            "LC": "onlyoffice.com",
            "PM": "onlyoffice.com",
            "VC": "onlyoffice.com",
            "WS": "onlyoffice.sg",
            "SM": "onlyoffice.eu",
            "ST": "onlyoffice.eu",
            "SA": "onlyoffice.eu",
            "SN": "onlyoffice.eu",
            "CS": "onlyoffice.com",
            "RS": "onlyoffice.com",
            "SC": "onlyoffice.eu",
            "SL": "onlyoffice.eu",
            "SG": "onlyoffice.sg",
            "SK": "onlyoffice.eu",
            "SI": "onlyoffice.eu",
            "SB": "onlyoffice.sg",
            "SO": "onlyoffice.eu",
            "ZA": "onlyoffice.eu",
            "GS": "onlyoffice.com",
            "ES": "onlyoffice.eu",
            "LK": "onlyoffice.sg",
            "SD": "onlyoffice.eu",
            "SR": "onlyoffice.com",
            "SJ": "onlyoffice.eu",
            "SZ": "onlyoffice.eu",
            "SE": "onlyoffice.eu",
            "CH": "onlyoffice.eu",
            "SY": "onlyoffice.eu",
            "TW": "onlyoffice.sg",
            "TJ": "onlyoffice.eu",
            "TZ": "onlyoffice.eu",
            "TH": "onlyoffice.sg",
            "TL": "onlyoffice.sg",
            "TG": "onlyoffice.eu",
            "TK": "onlyoffice.sg",
            "TO": "onlyoffice.sg",
            "TT": "onlyoffice.com",
            "TN": "onlyoffice.eu",
            "TR": "onlyoffice.eu",
            "TM": "onlyoffice.eu",
            "TC": "onlyoffice.com",
            "TV": "onlyoffice.sg",
            "UG": "onlyoffice.eu",
            "UA": "onlyoffice.eu",
            "AE": "onlyoffice.eu",
            "GB": "onlyoffice.eu",
            "US": "onlyoffice.com",
            "UM": "onlyoffice.com",
            "UY": "onlyoffice.com",
            "UZ": "onlyoffice.eu",
            "VU": "onlyoffice.sg",
            "VA": "onlyoffice.eu",
            "VE": "onlyoffice.com",
            "VN": "onlyoffice.sg",
            "VG": "onlyoffice.com",
            "VI": "onlyoffice.com",
            "WF": "onlyoffice.sg",
            "EH": "onlyoffice.eu",
            "YE": "onlyoffice.eu",
            "ZM": "onlyoffice.eu",
            "ZW": "onlyoffice.eu"
        ]
        return domainRegion[regin] ?? "onlyoffice.com"
    }
}
