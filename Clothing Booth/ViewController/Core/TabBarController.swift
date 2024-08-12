//
//  TabBarController.swift
//  Outfitter
//
//  Created by David Riegel on 06.05.24.
//

import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViewController()
    }

    func setupViewController() {
        let HomeController = HomeController()
        let GeneratorController = GeneratorController()
        let MyProfileController = MyProfileController()
        
        let navHomeController = UINavigationController(rootViewController: HomeController)
        let navGeneratorController = UINavigationController(rootViewController: GeneratorController)
        let navMyProfileController = UINavigationController(rootViewController: MyProfileController)
        
        navHomeController.tabBarItem = UITabBarItem(title: "home", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))
        navGeneratorController.tabBarItem = UITabBarItem(title: "create", image: UIImage(systemName: "plus.app"), selectedImage: UIImage(systemName: "plus.app.fill"))
        navMyProfileController.tabBarItem = UITabBarItem(title: "profile", image: UIImage(systemName: "person"), selectedImage: UIImage(systemName: "person.fill"))
        
        //navHomeController.tabBarItem.badgeColor = .label
        //navProfileViewController.tabBarItem.badgeColor = .label
        
        tabBar.tintColor = .label
        tabBar.backgroundColor = .systemBackground
        
        setViewControllers([navHomeController, navGeneratorController, navMyProfileController], animated: false)
    }
}
