//
//  UIView+Extension.swift
//  Documents
//
//  Created by Alexander Yuzhin on 9/10/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

extension UIView {
    
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "position.x")
        
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        animation.duration = 0.3
        animation.values = [ 0.0, 20.0, -20.0, 10.0, 0.0 ]
        animation.keyTimes = [ 0.0, NSNumber(value: 1.0 / 6.0), NSNumber(value: 3.0 / 6.0), NSNumber(value: 5.0 / 6.0), 1.0 ]
        animation.isAdditive = true
        
        layer.add(animation, forKey: "shake")
    }
}
