//
//  ASCGoogleSignInController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 6/5/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import GoogleSignIn
import Firebase

typealias ASCGoogleSignInHandler = (_ token: String?, _ error: Error?) -> Void

class ASCGoogleSignInController: NSObject, GIDSignInDelegate, GIDSignInUIDelegate {
    // MARK: - Properties
    
    private var signInHandler: ASCGoogleSignInHandler?
    private var presentedController: UIViewController?
    
    // MARK: - Public
    
    func signIn(controller: UIViewController, handler: @escaping ASCGoogleSignInHandler) {
        if let googleSignIn = GIDSignIn.sharedInstance() {
            
            presentedController = controller
            signInHandler = handler
            
            googleSignIn.clientID = FirebaseApp.app()?.options.clientID
            googleSignIn.scopes = ["email", "profile"]
            googleSignIn.shouldFetchBasicProfile = true
            googleSignIn.delegate = self
            googleSignIn.uiDelegate = self
            
            // Logout
            signOut()
            
            // Login
            googleSignIn.signIn()
        }
    }
    
    func signOut() {
        if let googleSignIn = GIDSignIn.sharedInstance() {
            googleSignIn.signOut()
            googleSignIn.disconnect()
        }
    }
    
    // MARK: - GoogleSignIn Delegate
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error == nil {
            signInHandler?(user.authentication.accessToken, nil)
        } else {
            signInHandler?(nil, error)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        presentedController?.present(viewController, animated: true, completion: nil)
    }
    
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        viewController.dismiss(animated: true, completion: nil)
    }
}
