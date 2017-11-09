//
//  ASCSSOSignInController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 8/28/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

typealias ASCSSOSignInHandler = (_ token: String?, _ error: Error?) -> Void

class ASCSSOSignInController: UIViewController, UIWebViewDelegate {

    // MARK: - Properties
    
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var signInHandler: ASCSSOSignInHandler?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView?.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func signIn(ssoUrl: String, handler: @escaping ASCSSOSignInHandler) {
        signInHandler = handler
        
        let urlRequest = URLRequest(url: URL(string: ssoUrl)!)
        webView?.loadRequest(urlRequest)
    }
    
    private func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
    
    // MARK: - UIWebView Delegate
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        debugPrint("webview url = \(request)")
        
        guard let host = request.url?.host, let request = request.url?.absoluteString else { return false }

        title = host
        
        if let errorCode = getQueryStringParameter(url: request, param: "error") {
            debugPrint("Error: \(errorCode)")
            
            UIAlertController.showError(in: self, message: String(format: NSLocalizedString("Please retry. \n\n If the problem persists contact us and mention this error code: SSO - %@", comment: ""), errorCode))
            return false
        }
        
        if let token = getQueryStringParameter(url: request, param: "token") {
            signInHandler?(token, nil)
            navigationController?.dismiss(animated: true, completion: nil)
            return false
        }
        
        return true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        activityIndicator?.stopAnimating()
        activityIndicator?.isHidden = true
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        debugPrint(error)
        
        let alertController = UIAlertController(title: NSLocalizedString("Error", comment:""), message: error.localizedDescription, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] action in
            self?.dismiss(animated: true, completion: nil)
        }))
        
        alertController.view.tintColor = view.tintColor
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Actions
    
    @IBAction func onDone(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}
