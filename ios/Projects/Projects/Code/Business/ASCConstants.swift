//
//  ASCConstants.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/17/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import Foundation
import UIKit

class ASCConstants {
    struct Urls {
        static let portalPersonal           = "://personal.onlyoffice.com"
        static let apiSystemUrl             = "https://api-system.%@"
        static let apiValidatePortalName    = "api/registration/validateportalname"
        static let apiRegistrationPortal    = "api/registration/registerportal"
        static let apiForgetPassword        = "https://%@/auth.aspx#passrecovery"
    }
    
    struct SettingsKeys {
        static let portalUrl                = "asc-portal-url"
        static let accessToken              = "asc-portal-token"
        static let portalLDAP               = "asc-portal-ldap"
        static let portalSSO                = "asc-portal-sso"
        static let portalSSOLabel           = "asc-portal-sso-label"
        static let lastCategory             = "asc-last-category"
        static let user                     = "asc-user"
        static let userName                 = "asc-user-name"
        static let userPortal               = "asc-user-portal"
        static let userEmail                = "asc-user-email"
        static let userAvatar               = "asc-user-avatar"
        static let compressImage            = "asc-settings-compress-image"
        static let allowBiometricId         = "asc-settings-allow-biometricid"
        static let pushAllow                = "asc-push-allow"
        static let pushDeviceToken          = "asc-push-device-token"
        static let pushFCMToken             = "asc-push-fcm-token"
        static let sdkVersion               = "asc-sdk-version"
        static let userAccounts             = "asc-accounts"
        
        static func setupDefaults() {
            UserDefaults.standard.register(defaults: [ASCConstants.SettingsKeys.compressImage: true])
            UserDefaults.standard.register(defaults: [ASCConstants.SettingsKeys.allowBiometricId: true])
        }
    }
    
    struct Shortcuts {
        static let newTask                  = "asc-shortcut-new-task"
        static let newProject               = "asc-shortcut-new-project"
    }

    struct Notifications {
        static let loginCompleted       = Notification.Name("ASCEventLogInCompleted")
        static let logoutCompleted      = Notification.Name("ASCEventLogOutCompleted")
        static let loginCode            = Notification.Name("ASCEventLoginCode")
        static let userInfoUpdate       = Notification.Name("ASCEventUserInfoUpdate")
        static let shortcutLaunch       = Notification.Name("ASCEventShortcutLaunch")
        static let networkStatusChanged = Notification.Name("ASCEventNetworkStatusChanged")
        static let updateSizeClass      = Notification.Name("ASCEventUpdateSizeClass")
        static let appDidBecomeActive   = Notification.Name("ASCEventAppDidBecomeActive")
    }

    struct FileExtensions {
        static let documents            = ["doc", "docx", "odt", "rtf", "mht", "html", "htm", "fb2", "epub"]
        static let spreadsheets         = ["xls", "xlsx", "csv", "ods"]
        static let presentations        = ["ppt", "pptx", "odp"]
        static let images               = ["jpg", "jpeg", "png", "gif", "bmp", "tif", "tiff", "ico"]
        static let video                = ["mp4", "m4v", "mov", "3gp"]
    }

    struct FolderProvider {
        static let boxNet           	= "Box"
        static let dropBox          	= "DropboxV2"
        static let google               = "Google"
        static let googleDrive          = "GoogleDrive"
        static let sharePoint           = "SharePoint"
        static let skyDrive             = "SkyDrive"
        static let webDav               = "WebDav"
        static let yandex               = "Yandex"
    }
    
    struct Size {
        static let defaultPreferredContentSize = CGSize(width: 540, height: 620)
    }
    
    struct Colors {
        static let brend                = UIColor(hex: "#2d6bb0")
        static let red                  = UIColor(hex: "#ff3b30")
        static let darkerGrey           = UIColor(hex: "#424245")
        static let darkGrey             = UIColor(hex: "#555555")
        static let grey                 = UIColor(hex: "#999da6")
        static let lightGrey            = UIColor(hex: "#c8c7cc")
        static let lighterGrey          = UIColor(hex: "#eff1f3")
    }
}
