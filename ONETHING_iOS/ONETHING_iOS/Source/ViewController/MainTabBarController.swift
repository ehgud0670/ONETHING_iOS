//
//  MainTabBarController.swift
//  ONETHING_iOS
//
//  Created by sdean on 2021/07/13.
//

import Lottie
import UIKit

// MARK: Internal Methods
extension MainTabBarController {
    
    func processLogout() {
        guard let loginViewController = LoginViewController.instantiateViewController(from: .intro) else { return }
        let navigationController = UINavigationController(rootViewController: loginViewController)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.setNavigationBarHidden(true, animated: false)
        self.present(navigationController, animated: true) { [weak self] in
            guard let self = self else { return }
            self.selectedIndex = 0
            self.moveToRoot()
            self.clearChildControllers()
        }
    }
    
    func broadCastRequiredReload() {
        self.setupUserInformIfNeeded()
        
        self.viewControllers?.forEach { viewController in
            guard let navigationController = viewController as? UINavigationController else { return }
            guard let topController = navigationController.topViewController else { return }
            guard let baseController = topController as? BaseViewController else { return }
            guard baseController.isViewLoaded == true else { return }
            
            baseController.reloadContentsIfRequired()
        }
    }

}

final class MainTabBarController: UITabBarController {
    private let viewModel = MainTabbarViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupTabBar()
        self.setupViewControllers()
        self.setupUserInformIfNeeded()
        
        DispatchQueue.main.async {
            self.decideStartController()
        }
    }
    
    private func setupTabBar() {
        if #available(iOS 15.0, *) {
            self.setupTabBarBackgroundForiOS15Above()
        } else {
            self.setupTabBarBackgroundForiOS14Below()
        }
        
        self.tabBar.layer.applyShadow(x: 0, y: 0, blur: 30.0)
        self.tabBar.tintColor = .black_100
    }
    
    private func setupViewControllers() {
        self.viewControllers = Child.allCases.map {
            $0.createController()
        }
    }
    
    private func setupTabBarBackgroundForiOS14Below() {
        self.tabBar.barTintColor = .white
        self.tabBar.isTranslucent = false
        self.tabBar.backgroundImage = UIImage()
        self.tabBar.shadowImage = UIImage()
    }
    
    @available(iOS 15.0, *)
    private func setupTabBarBackgroundForiOS15Above() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .white
        self.tabBar.standardAppearance = appearance
        self.tabBar.scrollEdgeAppearance = appearance
    }
    
    private func setupUserInformIfNeeded() {
        guard OnethingUserManager.sharedInstance.hasAccessToken == true else { return }
        self.viewModel.requestUserInformation()
    }
    
    private func decideStartController() {
        if OnethingUserManager.sharedInstance.hasAccessToken == false {
            self.presentLoginViewController()
            return
        }
        
        OnethingUserManager.sharedInstance.requestAccount(completion: { accountModel in
            guard accountModel.doneHabitSetting == false else {
                return
            }
            
            self.presentGoalSettingVCOrProfileSettingVC(with: accountModel)
        })
    }
    
    private func presentLoginViewController() {
        guard let loginViewController = LoginViewController.instantiateViewController(from: .intro) else {
            return
        }
        
        guard let navigationController = UIViewController.navigationController(loginViewController) else {
            return
        }
        
        self.present(navigationController, animated: false)
    }
    
    private func presentGoalSettingVCOrProfileSettingVC(with accountModel: OnethingAccountModel) {
        let goalSettingVC = GoalSettingFirstViewController.instantiateViewController(from: .goalSetting)
        let navigationController = UIViewController.navigationController(goalSettingVC)
        navigationController?.setupEnableSwipeBackMotion()
        
        guard let navigationController else { return }
        
        // MARK: 습관 설정 화면을 present 하되, NickName 이 없는 경우 프로필 설정화면으로 이동합니다.
        self.present(navigationController, animated: false, completion: {
            
            if accountModel.account?.nickname == nil {
                guard let profileSettingVC = ProfileSettingViewController.instantiateViewController(from: .intro) else {
                    return
                }
                
                profileSettingVC.modalPresentationStyle = .fullScreen
                navigationController.present(profileSettingVC, animated: false)
            }
            
        })
    }

    private func moveToRoot() {
        guard let viewControllers = self.viewControllers else { return }
        viewControllers.forEach { viewController in
            guard let navigationController = viewController as? UINavigationController else { return }
            navigationController.popToRootViewController(animated: false)
        }
    }
    
    private func clearChildControllers() {
        guard let viewControllers = self.viewControllers else { return }
        viewControllers.forEach { viewController in
            guard let navigationController = viewController as? UINavigationController else { return }
            guard let topController = navigationController.topViewController           else { return }
            guard let baseController = topController as? BaseViewController            else { return }
            guard baseController.isViewLoaded == true                                  else { return }
            baseController.clearContents()
        }
    }

}

extension MainTabBarController {
    
    enum Child: CaseIterable {
        case home
        case myhabit
        case mypage
        
        private var tabbarImage: UIImage? {
            switch self {
            case .home:     return UIImage(named: "home_inactive")
            case .myhabit:  return UIImage(named: "history_inactive")
            case .mypage:   return UIImage(named: "mypage_inactive")
            }
        }
        
        fileprivate func createController() -> UIViewController {
            var childController: UIViewController
            switch self {
            case .home:
                childController = HomeViewController()
            case .myhabit:
                childController = MyHabitViewController()
            case .mypage:
                childController = ProfileViewController.instantiateViewController(from: .profile) ?? ProfileViewController()
            }
            
            let navigationController = UINavigationController(rootViewController: childController)
            navigationController.tabBarItem.image = self.tabbarImage
            navigationController.isNavigationBarHidden = true
            return navigationController
        }
    }
    
}
