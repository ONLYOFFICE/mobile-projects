//
//  UISideMenuNavigationController+Extension.swift
//  Documents
//
//  Created by Alexander Yuzhin on 10/16/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import SideMenu

extension UISideMenuNavigationController {
    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIDevice.phone ? .portrait : [.portrait, .landscape]
    }
    
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIDevice.phone ? .portrait : super.preferredInterfaceOrientationForPresentation
    }
}
