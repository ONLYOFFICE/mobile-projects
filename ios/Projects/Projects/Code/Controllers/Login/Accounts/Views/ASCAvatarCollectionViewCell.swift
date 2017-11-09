//
//  ASCAvatarCollectionViewCell.swift
//  Documents
//
//  Created by Alexander Yuzhin on 10/23/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCAvatarCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    static let identifier = "ASCAvatarCollectionViewCell"
    
    private var token: NSKeyValueObservation?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.layer.cornerRadius = max(frame.size.width, frame.size.height) / 2
        self.layer.borderWidth = 5
        self.layer.borderColor = ASCConstants.Colors.brend.cgColor
        
        token = self.observe(\.alpha) { object, change in
            object.layer.borderWidth = object.alpha * 5
            object.layer.borderColor = ASCConstants.Colors.brend.saturate(object.alpha).cgColor
        }
    }
}
