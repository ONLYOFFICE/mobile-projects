//
//  ASCRootViewController.swift
//  Projects
//
//  Created by Alexander Yuzhin on 11/8/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import SideMenu

class ASCRootViewController: UIViewController {

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        ASCViewControllerManager.shared.contentNavigationController = navigationController
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Debug

    @IBAction func onShowMenu(_ sender: Any) {
        present(SideMenuManager.default.menuLeftNavigationController!, animated: true, completion: nil)
    }
}
