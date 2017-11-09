//
//  ASCAccountsManage.swift
//  Projects
//
//  Created by Alexander Yuzhin on 10/24/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import KeychainSwift

class ASCAccountsManage {
    public static let shared = ASCAccountsManage()
    
    private(set) var accounts: [ASCAccount] = []
    private let keychain = KeychainSwift()
    
    // MARK: - Private
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onUpdateUserInfo), name: ASCConstants.Notifications.userInfoUpdate, object: nil)        
        loadAccounts()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func loadAccounts() {
//        for index in 0..<5 {
//            if let account = ASCAccount(JSON:
//                [
//                    "email": "email \(index)",
//                    "displayName": "name \(index)",
//                    "avatar": "avatar  \(index)",
//                    "portal": "apiBaseUrl  \(index)",
//                    "token": "apiToken  \(index)"
//                ]
//                ) {
//                accounts.append(account)
//            }
//        }
//
//        return

        keychain.accessGroup = "2WH24U26GJ.com.onlyoffice.KeychainGroup"
        keychain.synchronizable = true

        NSKeyedUnarchiver.setClass(ASCAccount.self, forClassName: "Documents.ASCAccount")

        if let rawData = keychain.getData(ASCConstants.SettingsKeys.userAccounts),
            let array = NSKeyedUnarchiver.unarchiveObject(with: rawData) as? [ASCAccount] {
            accounts = array
        } else {
            accounts = []
            
            if let apiBaseUrl = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.portalUrl),
                let apiToken = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.accessToken) {
                
                if let account = ASCAccount(JSON: [
                    "portal": apiBaseUrl,
                    "token": apiToken
                    ]) {                    
                    add(account)
                }
            }
        }
    }
    
    private func storeAccounts() {
        let rawData = NSKeyedArchiver.archivedData(withRootObject: accounts)
        keychain.set(rawData, forKey: ASCConstants.SettingsKeys.userAccounts)
    }
    
    private func index(of account: ASCAccount) -> Int? {
        return accounts.index(where: { $0.email == account.email && $0.portal == account.portal })
    }
    
    @objc func onUpdateUserInfo() {
        if let user = ASCAccessManager.shared.user {
            if let account = ASCAccount(JSON: [
                "email": user.email ?? "",
                "displayName": user.displayName ?? "",
                "avatar": user.avatar ?? "",
                "portal": ASCApi.shared.baseUrl ?? "",
                "token": ASCApi.shared.token ?? ""
                ]) {
                add(account)
            }
        }
    }
    
    // MARK: - Public
    
    func add(_ account: ASCAccount) {
        if let _ = index(of: account) {
            update(account)
        } else {
            accounts.append(account)
            storeAccounts()
        }
    }
    
    func remove(_ account: ASCAccount) {
        if let index = index(of: account) {
            accounts.remove(at: index)
            storeAccounts()
        }
    }
    
    /// Update exist account
    ///
    /// - Parameter account: Search exist record to update by 'id' and 'portal' properties of ASCAccount object
    func update(_ account: ASCAccount) {
        if let index = index(of: account) {
            accounts[index] = account
            storeAccounts()
        }
    }
}
