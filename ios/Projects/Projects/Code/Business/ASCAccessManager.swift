//
//  ASCAccessManager.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/21/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Foundation
import ObjectMapper

class ASCAccessManager {
    public static let shared = ASCAccessManager()
    
    var user: ASCUser? = nil
    
    init() {
        if let userJSON = UserDefaults.standard.object(forKey: ASCConstants.SettingsKeys.user) as? [String: Any] {
            user = ASCUser(JSON: userJSON)
        }
    }
    
    func readUserInfo(_ completeon: ((Bool, String?) -> Void)? = nil) {
        ASCApi.get(ASCApi.apiPeopleSelf, parameters: nil) { [weak self] (results, error, response) in
            if let results = results as? [String: Any] {
                guard let strongSelf = self else { return }
                
                strongSelf.user = ASCUser(JSON: results)
                
                UserDefaults.standard.set(strongSelf.user?.displayName, forKey: ASCConstants.SettingsKeys.userName)
                UserDefaults.standard.set(ASCApi.shared.baseUrl, forKey: ASCConstants.SettingsKeys.userPortal)
                UserDefaults.standard.set(strongSelf.user?.email, forKey: ASCConstants.SettingsKeys.userEmail)
                UserDefaults.standard.set(strongSelf.user?.avatar, forKey: ASCConstants.SettingsKeys.userAvatar)
                UserDefaults.standard.set(strongSelf.user?.toJSON(), forKey: ASCConstants.SettingsKeys.user)
                
                NotificationCenter.default.post(name: ASCConstants.Notifications.userInfoUpdate, object: nil)
                
                completeon?(true, nil)
            } else {
                if let localResponse = response {
                    completeon?(false, ASCApi.errorMessage(by:localResponse))
                } else {
                    completeon?(false, nil)
                }
            }
        }
    }
    
//    func allowRead(entity: AnyObject?) -> Bool {
//        if let file = entity as? ASCFile {
//            return file.device || file.access != .restrict
//        }
//
//        if let folder = entity as? ASCFolder {
//            return folder.device || folder.access != .restrict
//        }
//
//        return false
//    }
//
//    func allowEdit(entity: AnyObject?) -> Bool {
//        let file = entity as? ASCFile
//        let folder = entity as? ASCFolder
//        let parentFolder = file?.parent ?? folder?.parent
//
//        if file == nil && folder == nil {
//            return false
//        }
//
//        let isDevice = (file?.device ?? folder?.device)!
//
//        if isDevice {
//            return parentFolder?.rootFolderType != .cloudTrash
//        } else {
//            guard let user = user else {
//                return false
//            }
//
//            if user.isVisitor {
//                return false
//            }
//
//            if let folder = folder {
//                if isRoot(folder: folder) && folder.rootFolderType == .cloudCommon && !user.isAdmin {
//                    return false
//                }
//
//                if isRoot(folder: folder) && folder.rootFolderType == .cloudShare {
//                    return false
//                }
//
//                if isRoot(folder: folder) && folder.rootFolderType == .cloudTrash {
//                    return false
//                }
//
//                if isRoot(folder: folder) && (folder.rootFolderType == .cloudProjects || folder.rootFolderType == .cloudBunch) {
//                    return false
//                }
//            }
//
//            var access: ASCEntityAccess = ((file != nil) ? file?.access : folder?.access)!
//
//            if let parentFolder = parentFolder, let folder = folder, folder.id == parentFolder.id {
//                access = parentFolder.access
//            }
//
//            switch (access) {
//            case .none, .readWrite:
//                return true
//            case .read, .restrict:
//                return false
//            }
//        }
//    }
//
//    func allowDelete(entity: AnyObject) -> Bool {
//        let file = entity as? ASCFile
//        let folder = entity as? ASCFolder
//        let parentFolder = file?.parent ?? folder?.parent
//
//        if file == nil && folder == nil {
//            return false
//        }
//
//        let isDevice =  (file?.device ?? folder?.device)!
//
//        if isDevice {
//            return true
//        } else {
//            guard let user = user else {
//                return false
//            }
//
//            if user.isVisitor {
//                return false
//            }
//
//            var access = (file != nil) ? file?.access : folder?.access;
//
//            if folder != nil && folder?.id == parentFolder?.id {
//                access = parentFolder?.access
//            }
//
//            if access == .restrict {
//                return false
//            }
//
//            if isRoot(folder: parentFolder) && (parentFolder?.rootFolderType == .cloudBunch || parentFolder?.rootFolderType == .cloudProjects) {
//                return false
//            }
//
//            // Is root third-party directory
//            if isRoot(folder: parentFolder) && folder?.isThirdParty == true {
//                return false
//            }
//
//            let isProjectRoot = isRoot(folder: parentFolder) && (parentFolder?.rootFolderType == .cloudBunch || parentFolder?.rootFolderType == .cloudProjects)
//
//            return (access == .none
//                || ((file != nil ? file?.rootFolderType == .cloudCommon : folder?.rootFolderType == .cloudCommon) && user.isAdmin)
//                || (!isProjectRoot && (file != nil ? user.userId == file?.createdBy?.userId : user.userId == folder?.createdBy?.userId)))
//        }
//    }

    private func isRoot(folder: ASCFolder?) -> Bool {
        if let folder = folder {
            return folder.parentId == nil || folder.parentId == "0"
        }
        
        return false
    }
}
