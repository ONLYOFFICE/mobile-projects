//
//  ASCAccountsViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 10/23/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import Kingfisher

class ASCAccountsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var accountsCollectionView: UICollectionView!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var portalLabel: UILabel!
    @IBOutlet weak var labelsView: UIStackView!
    @IBOutlet weak var continueButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if ASCAccountsManage.shared.accounts.count < 1 {
            switchVCSingle()
            return
        }
        
        setupLayout()
        currentPage = 0
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.shadowImage = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func setupLayout() {
        if let layout = accountsCollectionView.collectionViewLayout as? UPCarouselFlowLayout {
            layout.spacingMode = UPCarouselFlowLayoutSpacingMode.fixed(spacing: 40)
        }
    }
    
    private var currentPage: Int = -1 {
        didSet {
            if currentPage == oldValue || currentPage < 0 {
                return
            }
            
            updateInfo(pageIndex: currentPage)
        }
    }
    
    private var pageSize: CGSize {
        if let layout = accountsCollectionView.collectionViewLayout as? UPCarouselFlowLayout {
            var pageSize = layout.itemSize
            if layout.scrollDirection == .horizontal {
                pageSize.width += layout.minimumLineSpacing
            } else {
                pageSize.height += layout.minimumLineSpacing
            }
            return pageSize
        }
        
        return .zero
    }
    
    private func updateInfo(pageIndex: Int) {
        let animationDuration = 0.6
        
        view.subviews.forEach({$0.layer.removeAllAnimations()})
        view.layer.removeAllAnimations()
        view.layoutIfNeeded()
        
        if pageIndex < 0 || pageIndex >= ASCAccountsManage.shared.accounts.count {
            UIView.animate(withDuration: animationDuration / 2, animations: { [weak self] in
                self?.labelsView?.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                self?.labelsView?.alpha = 0
            }) { [weak self] (completed) in
                self?.displayNameLabel?.text = ""
                self?.portalLabel?.text = ""
                
                UIView.animate(withDuration: animationDuration / 2) { [weak self] in
                    self?.labelsView?.transform = CGAffineTransform(scaleX: 1, y: 1)
                    self?.labelsView?.alpha = 1
                }
            }
            return
        }
        
        let account = ASCAccountsManage.shared.accounts[currentPage]
        
        UIView.animate(withDuration: animationDuration / 2, animations: { [weak self] in
            self?.labelsView?.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            self?.labelsView?.alpha = 0
        }) { [weak self] (completed) in
            self?.displayNameLabel?.text = account.email ?? NSLocalizedString("Unknown", comment: "")
            self?.portalLabel?.text = URL(string: account.portal ?? "")?.host ?? account.portal
            
            UIView.animate(withDuration: animationDuration / 2) { [weak self] in
                self?.labelsView?.transform = CGAffineTransform(scaleX: 1, y: 1)
                self?.labelsView?.alpha = 1
            }
        }
    }
    
    private func calcCurrentPage(by scrollView: UIScrollView) {
        if let layout = accountsCollectionView.collectionViewLayout as? UPCarouselFlowLayout {
            let pageSide = (layout.scrollDirection == .horizontal) ? pageSize.width : pageSize.height
            let offset = (layout.scrollDirection == .horizontal) ? scrollView.contentOffset.x : scrollView.contentOffset.y
            let page = Int(floor((offset - pageSide / 2) / pageSide) + 1)
            
            if page > -1 && page < ASCAccountsManage.shared.accounts.count {
                currentPage = page
            }
        }
    }
    
    private func switchVCSingle() {
        if ASCAccountsManage.shared.accounts.count < 1 {
            if let connectPortalVC = storyboard?.instantiateViewController(withIdentifier: "ConnectPortalViewController") as? ASCConnectPortalViewController {
                navigationController?.viewControllers = [connectPortalVC]
            }
        }
    }

    private func absoluteUrl(from url: URL?, for portal: String) -> URL? {
        if let url = url {
            if let _ = url.host {
                return url
            } else {
                return URL(string: portal + url.absoluteString)
            }
        }
        return nil
    }
    
    // MARK: - Actions
    
    @IBAction func onDeleteAccount(_ sender: UIBarButtonItem) {
        let account = ASCAccountsManage.shared.accounts[currentPage]
        
        let deleteController = UIAlertController(title: String(format: NSLocalizedString("Are you sure you want to delete the account %@ from this device?", comment: ""), account.email ?? ""), message: nil, preferredStyle: UIDevice.phone ? .actionSheet : .alert)
        
        deleteController.addAction(title: NSLocalizedString("Delete account", comment: ""), style: .destructive, handler: { [weak self] action in
            ASCAccountsManage.shared.remove(account)
            
            if ASCAccountsManage.shared.accounts.count < 1 {
                self?.switchVCSingle()
                return
            }
            
            guard let pageIndex = self?.currentPage else { return }
            
            self?.accountsCollectionView.deleteItems(at: [IndexPath(row: pageIndex, section: 0)])
            
            if pageIndex >= ASCAccountsManage.shared.accounts.count && ASCAccountsManage.shared.accounts.count > 0 {
                self?.currentPage -= 1
            } else {
                self?.updateInfo(pageIndex: pageIndex)
            }
        })
        
        deleteController.addCancel()
        
        present(deleteController, animated: true, completion: nil)
    }
    
    @IBAction func onContinue(_ sender: UIButton) {
        sender.isUserInteractionEnabled = false
        sender.isEnabled = false
        
        let api = ASCApi.shared
        let account = ASCAccountsManage.shared.accounts[currentPage]
        
        if let baseUrl = account.portal, let token = account.token {
            api.baseUrl = baseUrl
            api.token = token
            
            // Save auth info into user perfomances
            UserDefaults.standard.set(baseUrl, forKey: ASCConstants.SettingsKeys.portalUrl)
            UserDefaults.standard.set(token, forKey: ASCConstants.SettingsKeys.accessToken)
            
            NotificationCenter.default.post(name: ASCConstants.Notifications.loginCompleted, object: nil)
            
            // Registration device into the portal
            ASCApi.post(ASCApi.apiDeviceRegistration, parameters: ["type": 2], completion: { (_, _, _) in
                // 2 - IOSDocuments
            })

            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func onClose(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Collection Delegate
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ASCAccountsManage.shared.accounts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ASCAvatarCollectionViewCell.identifier, for: indexPath) as? ASCAvatarCollectionViewCell {
            let account = ASCAccountsManage.shared.accounts[indexPath.row]
            let avatarUrl = absoluteUrl(from: URL(string: account.avatar ?? ""), for: account.portal ?? "")

            cell.imageView.kf.setImage(with: avatarUrl, placeholder: UIImage(named: "avatar-default"))

            return cell
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == currentPage {
            onContinue(continueButton)
            return
        }
        
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    // MARK: - ScrollView Delegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        calcCurrentPage(by: scrollView)
    }

}
