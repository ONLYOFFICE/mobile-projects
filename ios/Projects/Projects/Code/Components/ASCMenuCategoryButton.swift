//
//  ASCMenuCategoryButton.swift
//  Documents
//
//  Created by Alexander Yuzhin on 3/20/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit

@IBDesignable
class ASCMenuCategoryButton: UIButton {

    // MARK: - Properties
    
    var markView: UIView?
    
    // MARK: - Lifecycle Methods
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setTitleColor(ASCConstants.Colors.brend, for: .selected)
        setTitleColor(ASCConstants.Colors.brend, for: .highlighted)
        setTitleColor(ASCConstants.Colors.darkGrey, for: .normal)
        
        setTitle(title(for: .selected), for: .selected)
        setTitle(title(for: .normal), for: .normal)
        
        let origImage = image(for: .normal)
        let tintedImage = origImage?.withRenderingMode(.alwaysTemplate)
        setImage(tintedImage, for: .selected)
        setImage(tintedImage, for: .highlighted)
        setImage(tintedImage, for: .normal)
        tintColor = ASCConstants.Colors.darkGrey
        
        markView = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: bounds.height))
        addSubview(markView!)
    }
    
    override var isSelected: Bool {
        didSet {
            tintColor = isSelected ? ASCConstants.Colors.brend : ASCConstants.Colors.darkGrey
            markView?.backgroundColor = isSelected ? tintColor : .clear
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            tintColor = isHighlighted || isSelected ? ASCConstants.Colors.brend : ASCConstants.Colors.darkGrey
            markView?.backgroundColor = isHighlighted || isSelected ? tintColor : .clear
        }
    }
    
    @IBInspectable
    var selectedColor: UIColor = UIColor.red {
        didSet {
            setBackgroundColor(color: selectedColor, forState: .selected)
        }
    }

    @IBInspectable
    var highlightColor: UIColor = UIColor.lightGray {
        didSet {
            setBackgroundColor(color: highlightColor, forState: .highlighted)
        }
    }
    
    // MARK: - Private
    
    private func setBackgroundColor(color: UIColor, forState: UIControlState) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.setBackgroundImage(colorImage, for: forState)
    }
}
