//
//  ASCUserProfileViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/18/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import Kingfisher
import MBProgressHUD

class ASCUserProfileViewController: UITableViewController {

    // MARK: - Properties
    @IBOutlet weak var canvasView: UIView!
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var portalLabel: UILabel!
    @IBOutlet weak var emailTitleLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var logoutCell: UITableViewCell!
    
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateUserUnfo(_:)), name: ASCConstants.Notifications.userInfoUpdate, object: nil)
        
        avatarView.kf.indicatorType = .activity
        designAvatarView(avatarView)
        
        if UIDevice.pad {
            preferredContentSize = ASCConstants.Size.defaultPreferredContentSize
        }
        
        var canvasFrame = canvasView.frame
        canvasFrame.size.height = UIDevice.phone ? UIDevice.height - 220 : preferredContentSize.height - 150
        canvasView.frame = canvasFrame
        
        emailTitleLabel?.text = UserDefaults.standard.bool(forKey: ASCConstants.SettingsKeys.portalLDAP)
            ? NSLocalizedString("Login", comment: "")
            : NSLocalizedString("Email", comment: "")
        
        if let user = ASCAccessManager.shared.user {
            userNameLabel.text = user.displayName
            portalLabel.text = ASCApi.shared.baseUrl
            emailLabel.text = user.email

            let avatarUrl = ASCApi.absoluteUrl(from: URL(string: user.avatar ?? ""))
            avatarView.kf.setImage(with: avatarUrl, placeholder: UIImage(named: "avatar-default"));
        } else {
            userNameLabel.text = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.userName) ?? "-"
            portalLabel.text = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.userPortal) ?? "-"
            emailLabel.text = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.userEmail) ?? "-"

            let avatarUrl = ASCApi.absoluteUrl(from: URL(string: UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.userAvatar) ?? ""))
            avatarView.kf.setImage(with: avatarUrl, placeholder: UIImage(named: "avatar-default"));
        }
    }
    
    deinit {
         NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    static func logout() {
        // Cleanup userinfo
        ASCAccessManager.shared.user = nil
        UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.userName)
        UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.userPortal)
        UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.userEmail)
        UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.userAvatar)
        UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.user)
        
        // Cleanup auth info
        ASCApi.shared.baseUrl = nil
        ASCApi.shared.token = nil
        UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.portalUrl)
        UserDefaults.standard.removeObject(forKey: ASCConstants.SettingsKeys.accessToken)
        
        NotificationCenter.default.post(name: ASCConstants.Notifications.logoutCompleted, object: nil)
    }

    // MARK: - Private
    
    private func designAvatarView(_ imageView: UIImageView!) {
        let radius = avatarView.bounds.width * 0.5
        imageView.layer.cornerRadius = radius
        imageView.layer.masksToBounds = true
        
        let shapeLayer1 = CAShapeLayer()
        let lineWidth: CGFloat = 2.0
        let frameSize = imageView.frame.size
        var shapeRect = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
        
        shapeLayer1.bounds = shapeRect
        shapeLayer1.position = CGPoint(x: radius, y: radius)
        shapeLayer1.fillColor = UIColor.clear.cgColor
        shapeLayer1.strokeColor = ASCConstants.Colors.lighterGrey.cgColor
        shapeLayer1.lineWidth = lineWidth
        shapeLayer1.lineJoin = kCALineJoinRound
        shapeLayer1.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: radius).cgPath
        imageView.layer.addSublayer(shapeLayer1)
        
        let shapeLayer2 = CAShapeLayer()
        shapeRect = CGRect(x: 0, y: 0, width: frameSize.width - 2 * lineWidth, height: frameSize.height - 2 * lineWidth)
        shapeLayer2.bounds = shapeRect
        shapeLayer2.position = CGPoint(x: radius, y: radius)
        shapeLayer2.fillColor = UIColor.clear.cgColor
        shapeLayer2.strokeColor = UIColor.white.cgColor
        shapeLayer2.lineWidth = lineWidth
        shapeLayer2.lineJoin = kCALineJoinRound
        shapeLayer2.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: radius - 2 * lineWidth).cgPath
        imageView.layer.addSublayer(shapeLayer2)
        
    }
    
    private func onLogout() {
        ASCUserProfileViewController.logout()
        
        if let hud = MBProgressHUD.showTopMost() {
            hud.setSuccessState(title: NSLocalizedString("Logout", comment: "Caption of the process"))
            hud.hide(animated: true, afterDelay: 2)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc func updateUserUnfo(_ notification: Notification) {
        userNameLabel?.text = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.userName)
        portalLabel?.text = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.userPortal)
        emailLabel?.text = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.userEmail)
        
        if let avatar = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.userAvatar), let avatarUrl = ASCApi.absoluteUrl(from: URL(string: avatar)) {
            avatarView?.kf.setImage(with: avatarUrl)
        }
    }
    
    // MARK: - Table view Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if cell == logoutCell {
            let logoutController = UIAlertController(title: NSLocalizedString("Are you sure you want to leave this account?", comment: ""), message: nil, preferredStyle: UIDevice.phone ? .actionSheet : .alert)
            
            logoutController.addAction(title: NSLocalizedString("Logout", comment: "Button title"), style: .destructive, handler: { action in
                self.onLogout()
            })
            
            logoutController.addCancel()
            
            present(logoutController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func onDone(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

}
