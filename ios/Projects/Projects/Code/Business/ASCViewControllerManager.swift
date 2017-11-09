//
//  ASCViewControllerManager.swift
//  Projects
//
//  Created by Alexander Yuzhin on 11/8/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import SideMenu
import SwiftRater
import Siren

class ASCViewControllerManager {
    public static let shared = ASCViewControllerManager()

    var currentSizeClass: UIUserInterfaceSizeClass {
        get {
            if let categoryController = self.categoryController as? ASCCategoryViewController {
                return categoryController.currentSizeClass
            }

            return .compact
        }
    }

    var categoryController: UIViewController? = nil {
        didSet {
            if oldValue == nil {
                initializeControllers()
            }
        }
    }
    var contentNavigationController: UINavigationController? = nil {
        didSet {
            if oldValue == nil {
                initializeControllers()
            }
        }
    }

    func initCategoryController(controller contentNavigationController: UINavigationController) -> Bool {
        if UIDevice.phone && SideMenuManager.default.menuLeftNavigationController == nil {
            SideMenuManager.default.menuLeftNavigationController = contentNavigationController.storyboard!.instantiateViewController(withIdentifier: "LeftMenuNavigationController") as? UISideMenuNavigationController

            SideMenuManager.default.menuAddPanGestureToPresent(toView: contentNavigationController.navigationBar)
//            SideMenuManager.default.menuAddPanGestureToPresent(toView: self.view)
            SideMenuManager.default.menuAddScreenEdgePanGesturesToPresent(toView: contentNavigationController.view, forMenu: .left)

            if let menuLeftNavigationController = SideMenuManager.default.menuLeftNavigationController {
                if let topViewController = menuLeftNavigationController.topViewController {
                    // Forece load view
                    _ = topViewController.view
                    return true
                }
            }
        }

        return false
    }

    func initializeControllers() {
        guard let contentNavigationController = contentNavigationController else {
            return
        }

        if initCategoryController(controller: contentNavigationController) {
            return
        }

        guard let categoryController = categoryController as? ASCCategoryViewController else {
            return
        }

        ASCConstants.SettingsKeys.setupDefaults()

        if let apiBaseUrl = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.portalUrl) {
            ASCApi.shared.baseUrl = apiBaseUrl
        }
        if let apiToken = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.accessToken) {
            ASCApi.shared.token = apiToken
        }

        // Open start category

        if false/* UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.forceCreateNewDocument) ||
             UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.forceCreateNewSpreadsheet) */ {
            // TODO: Lounsh via shortcut
            categoryController.showCategory(.projects)
        } else {
            categoryController.showCategory(ASCCategoryType(rawValue: UserDefaults.standard.integer(forKey: ASCConstants.SettingsKeys.lastCategory)) ?? .projects)
        }

//        // Check if first launch
//
//        let storeAppVersion = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.appVersion)
//
//        if let appVersion = ASCCommon.appVersion, storeAppVersion != appVersion {
//            UserDefaults.standard.set(appVersion, forKey: ASCConstants.SettingsKeys.appVersion)
//
//            if storeAppVersion == nil || appVersion.isVersion(lessThan: "2.0") {
//                prepareContent()
//                categoryController.showCategory(.deviceDocuments)
//                showIntro()
//            }
//        }

        configureRater()
        configureAppUpdater()
    }

    // MARK: - Private

    private func configureRater() {
        SwiftRater.daysUntilPrompt = 7
        SwiftRater.usesUntilPrompt = 5
        SwiftRater.significantUsesUntilPrompt = 2
        SwiftRater.daysBeforeReminding = 3
        SwiftRater.showLaterButton = true
//        SwiftRater.debugMode = true
        SwiftRater.showLog = true
        SwiftRater.appLaunched()
    }

    private func configureAppUpdater() {
        Siren.shared.alertType = .option
        Siren.shared.showAlertAfterCurrentVersionHasBeenReleasedForDays = 1
        Siren.shared.checkVersion(checkType: .immediately)
    }

    private func showIntro() {
//        if let documentsController = documentsNavigationController, let introController = documentsController.storyboard?.instantiateViewController(withIdentifier: "IntroViewController") as? ASCIntroViewController {
//            documentsController.present(introController, animated: true, completion: nil)
//        }
    }
}
