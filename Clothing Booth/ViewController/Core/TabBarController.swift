//
//  TabBarController.swift
//  Outfitter
//
//  Created by David Riegel on 06.05.24.
//

import UIKit

public class TabBarController: UITabBarController, UITabBarControllerDelegate {

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViewController()
    }

    private func setupViewController() {
        let HomeController = HomeController()
        let OutfitsController = OutfitsController()
        let ClothesController = ClothesController()
        let MyProfileController = MyProfileController()
        
        let navHomeController = UINavigationController(rootViewController: HomeController)
        let navOutfitsController = UINavigationController(rootViewController: OutfitsController)
        let navClothesController = UINavigationController(rootViewController: ClothesController)
        let navMyProfileController = UINavigationController(rootViewController: MyProfileController)
        
        navHomeController.tabBarItem = UITabBarItem(title: "home", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))
        navOutfitsController.tabBarItem = UITabBarItem(title: "outfits", image: UIImage(systemName: "cabinet"), selectedImage: UIImage(systemName: "cabinet.fill"))
        navClothesController.tabBarItem = UITabBarItem(title: "clothes", image: UIImage(systemName: "tshirt"), selectedImage: UIImage(systemName: "tshirt.fill"))
        navMyProfileController.tabBarItem = UITabBarItem(title: "profile", image: UIImage(systemName: "person"), selectedImage: UIImage(systemName: "person.fill"))
        
        tabBar.tintColor = .label
        tabBar.backgroundColor = .background
        
        setViewControllers([navHomeController, navOutfitsController, navClothesController, navMyProfileController], animated: false)
    }
}
