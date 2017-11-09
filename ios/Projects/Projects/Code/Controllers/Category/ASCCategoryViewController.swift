//
//  ASCCategoryViewController.swift
//  Projects
//
//  Created by Alexander Yuzhin on 11/8/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import SideMenu

class ASCCategoryViewController: UIViewController {

    // MARK: - Properties
    @IBOutlet weak var categoryProjects: UIButton!
    @IBOutlet weak var categoryMilestones: UIButton!
    @IBOutlet weak var categoryTasks: UIButton!
    @IBOutlet weak var categoryDiscussions: UIButton!
    @IBOutlet weak var categoryTimeTracking: UIButton!
    @IBOutlet weak var categoryDocuments: UIButton!
    @IBOutlet var allCategories: [UIButton]!
    @IBOutlet var userInfoView: UIView!
    @IBOutlet var connectView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userEmail: UILabel!


    var currentSizeClass: UIUserInterfaceSizeClass = .compact

    private var appScreenRect: CGRect {
        get {
            let appWindowRect = UIApplication.shared.keyWindow?.bounds ?? UIWindow().bounds
            return appWindowRect
        }
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        SideMenuManager.default.menuFadeStatusBar = false;
        SideMenuManager.default.menuPresentMode = .viewSlideOut
        SideMenuManager.default.menuShadowRadius = 10
        SideMenuManager.default.menuShadowOpacity = 0.3
        SideMenuManager.default.menuWidth = appScreenRect.width - 60.0

        ASCViewControllerManager.shared.categoryController = self

        NotificationCenter.default.addObserver(self, selector: #selector(onLoginCompleted(_:)), name: ASCConstants.Notifications.loginCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onLogoutCompleted(_:)), name: ASCConstants.Notifications.logoutCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUserInfo), name: ASCConstants.Notifications.userInfoUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(networkStatusChanged), name: ASCConstants.Notifications.networkStatusChanged, object: nil)

        if UIDevice.phone {
            initHeaderView()
            initCategories()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if UIDevice.pad {
            initHeaderView()
            initCategories()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIDevice.phone ? .portrait : [.portrait, .landscape]
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIDevice.phone ? .portrait : super.preferredInterfaceOrientationForPresentation
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if currentSizeClass != traitCollection.horizontalSizeClass && UIDevice.pad {
            currentSizeClass = traitCollection.horizontalSizeClass
            NotificationCenter.default.post(name: ASCConstants.Notifications.updateSizeClass, object: currentSizeClass)
        }
    }

    func showCategory(_ categoryType: ASCCategoryType) {
        guard let contentNavigationController = ASCViewControllerManager.shared.contentNavigationController else {
            return
        }

        if ASCApi.shared.baseUrl == nil || ASCApi.shared.token == nil {
            showLogin()
            return
        }

        contentNavigationController.popToRootViewController(animated: false)

        UserDefaults.standard.set(categoryType.rawValue, forKey: ASCConstants.SettingsKeys.lastCategory)

        switch categoryType {
        case .projects:
            if let projectsViewController = storyboard?.instantiateViewController(withIdentifier: "ProjectsViewController") as? ASCProjectsViewController {
                selectCategory(categoryProjects)
                contentNavigationController.viewControllers = [projectsViewController]
            }
            break
        case .milestones:
            if let dummyViewController = storyboard?.instantiateViewController(withIdentifier: "RootViewController") as? ASCRootViewController {
                selectCategory(categoryMilestones)
                contentNavigationController.viewControllers = [dummyViewController]
            }
            break
        case .tasks:
            if let dummyViewController = storyboard?.instantiateViewController(withIdentifier: "RootViewController") as? ASCRootViewController {
                selectCategory(categoryTasks)
                contentNavigationController.viewControllers = [dummyViewController]
            }
            break
        case .discussions:
            if let dummyViewController = storyboard?.instantiateViewController(withIdentifier: "RootViewController") as? ASCRootViewController {
                selectCategory(categoryDiscussions)
                contentNavigationController.viewControllers = [dummyViewController]
            }
            break
        case .timeTracking:
            if let dummyViewController = storyboard?.instantiateViewController(withIdentifier: "RootViewController") as? ASCRootViewController {
                selectCategory(categoryTimeTracking)
                contentNavigationController.viewControllers = [dummyViewController]
            }
            break
        case .documents:
            if let dummyViewController = storyboard?.instantiateViewController(withIdentifier: "RootViewController") as? ASCRootViewController {
                selectCategory(categoryDocuments)
                contentNavigationController.viewControllers = [dummyViewController]
            }
            break
        default:
            break
        }


        dismiss(animated: true, completion: nil)
    }

    func selectCategory(_ category: UIButton) {
        if category.isSelected {
            return
        }

        for button in allCategories {
            button.isSelected = false
        }

        category.isSelected = true
    }

    // MARK: - Actions

    @IBAction func onProjectsCategory(_ sender: UIButton) {
        showCategory(.projects)
    }

    @IBAction func onMilestonesCategory(_ sender: UIButton) {
        showCategory(.milestones)
    }

    @IBAction func onTasksCategory(_ sender: UIButton) {
        showCategory(.tasks)
    }

    @IBAction func onDiscussionsCategory(_ sender: UIButton) {
        showCategory(.discussions)
    }

    @IBAction func onTimesCategory(_ sender: UIButton) {
        showCategory(.timeTracking)
    }

    @IBAction func onDocumentsCategory(_ sender: UIButton) {
        showCategory(.documents)
    }

    // MARK: - Navigation

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "sequeUserProfile" {
            ASCAccessManager.shared.readUserInfo({ success, error in
                if let localError = error {
                    if ASCApi.errorPaymentRequired == localError {
                        ASCBanner.shared.showError(title: NSLocalizedString("Payment required", comment: ""), message: NSLocalizedString("The paid period is over", comment: ""))
                    }
                }
            })

            if nil != ASCAccessManager.shared.user {
                return true
            } else {
                if nil != UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.userName) {
                    return true
                }

                let alertController = UIAlertController(title: NSLocalizedString("Error", comment:""),
                                                        message: NSLocalizedString("No information about the user profile.", comment: ""),
                                                        preferredStyle: .alert)

                alertController.addAction(UIAlertAction(title: NSLocalizedString("Logout", comment: "Button title"), style: .destructive, handler: { (action) in
                    ASCUserProfileViewController.logout()
                }))

                alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action) in
                    //
                }))

                alertController.view.tintColor = view.tintColor
                present(alertController, animated: true, completion: nil)

                return false
            }
        }

        return true
    }

    // MARK: - Notification

    @objc func onLoginCompleted(_ notification: Notification) {
        if nil != ASCAccessManager.shared.user {
            showCategory(.projects)
        }

        initHeaderView()
    }

    @objc func onLogoutCompleted(_ notification: Notification) {
        initHeaderView()
        initCategories()
        showLogin()
    }

    // MARK: - Private

    private func initHeaderView() {
        for subView in headerView?.subviews ?? [UIView]() {
            subView.removeFromSuperview()
        }

        let isAuthtorize = (ASCApi.shared.baseUrl != nil) && (ASCApi.shared.token != nil)

        func insertView(_ view: UIView) {
            headerView?.addSubview(view)

            view.translatesAutoresizingMaskIntoConstraints = false
            view.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 0).isActive = true
            view.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 0).isActive = true
            view.rightAnchor.constraint(equalTo: headerView.rightAnchor, constant: 0).isActive = true
            view.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 0).isActive = true
        }

        if isAuthtorize {
            insertView(userInfoView)

            let radius = avatarView.bounds.width * 0.5
            avatarView.layer.cornerRadius = radius
            avatarView.layer.masksToBounds = true
            avatarView.kf.indicatorType = .activity

            updateUserInfo()

            ASCAccessManager.shared.readUserInfo({ [weak self] success, error in
                if let localError = error {
                    if ASCApi.errorPaymentRequired == localError {
                        ASCBanner.shared.showError(title: NSLocalizedString("Payment required", comment: ""),
                                                   message: NSLocalizedString("The paid period is over", comment: ""))
                    }
                }

                if success {
                    self?.updateUserInfo()
                }
            })
        } else {
            insertView(connectView)
        }
    }

    private func initCategories() {
//        let api = ASCApi.shared
//        let isPersonal = (api.baseUrl?.contains(ASCConstants.Urls.portalPersonal)) ?? false //
//        let allowCloud = (api.baseUrl != nil) && (api.token != nil)
//
//        if let user = ASCAccessManager.shared.user, allowCloud {
//            myDocumentsConstraint?.constant = user.isVisitor ? 0 : deviceButtonsConstarints?.constant ?? 0
//            sharedDocumentsConstraint?.constant = isPersonal ? 0 : deviceButtonsConstarints?.constant ?? 0
//            commonDocumentsConstraint?.constant = isPersonal ? 0 : deviceButtonsConstarints?.constant ?? 0
//            projectsDocumentsConstraint?.constant = isPersonal ? 0 : deviceButtonsConstarints?.constant ?? 0
//        } else {
//            for constarint in [myDocumentsConstraint, sharedDocumentsConstraint, commonDocumentsConstraint, projectsDocumentsConstraint] {
//                constarint?.constant = deviceButtonsConstarints?.constant ?? 0
//            }
//        }
    }

    @objc func updateUserInfo() {
        if let user = ASCAccessManager.shared.user {
            let avatarUrl = ASCApi.absoluteUrl(from: URL(string: user.avatar ?? ""))

            userName?.text = user.displayName
            userEmail?.text = user.email
            avatarView.kf.setImage(with: avatarUrl, placeholder: UIImage(named: "avatar-default"))
        } else {
             let avatarUrl = ASCApi.absoluteUrl(from: URL(string: UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.userAvatar) ?? ""))
            userName?.text = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.userName) ?? NSLocalizedString("Me", comment: "If current user name is not set")
            userEmail?.text = UserDefaults.standard.string(forKey: ASCConstants.SettingsKeys.userEmail) ?? ""

            avatarView.kf.setImage(with: avatarUrl, placeholder: UIImage(named: "avatar-default"))
        }

        initCategories()
    }

    @objc func networkStatusChanged() {
        if !ASCApi.shared.isReachable && ASCApi.shared.token != nil {
            ASCBanner.shared.showError(title: NSLocalizedString("No network", comment: ""), message: NSLocalizedString("Check your internet connection", comment: ""))
        }
    }

    private func showLogin() {
        guard let documentsNavigationController = ASCViewControllerManager.shared.contentNavigationController else {
            return
        }

        guard let loginViewController = documentsNavigationController.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as? UINavigationController else {
            return
        }

        documentsNavigationController.present(loginViewController, animated: true, completion: nil)
    }

}
