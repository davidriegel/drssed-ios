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
        //let HomeController = HomeController()
        let ClothesController = ClothesGalleryController()
        let OutfitsController = OutfitsGalleryViewController()
        //let MyProfileController = SignUpController()
        
        ClothesController.title = String(localized: "wardrobe.title")
        OutfitsController.title = String(localized: "lookbook.title")
        //MyProfileController.title = String(localized: "auth.signup.title")
        
        //let navHomeController = UINavigationController(rootViewController: HomeController)
        let navClothesController = UINavigationController(rootViewController: ClothesController)
        let navOutfitsController = UINavigationController(rootViewController: OutfitsController)
        //let navMyProfileController = UINavigationController(rootViewController: MyProfileController)
        
        //navHomeController.tabBarItem = UITabBarItem(title: "home", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))
        navClothesController.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "tshirt"), selectedImage: UIImage(systemName: "tshirt.fill"))
        navOutfitsController.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "cabinet"), selectedImage: UIImage(systemName: "cabinet.fill"))
        //navMyProfileController.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "person"), selectedImage: UIImage(systemName: "person.fill"))
        
        navClothesController.tabBarItem.accessibilityLabel = String(localized: "wardrobe.title")
        navOutfitsController.tabBarItem.accessibilityLabel = String(localized: "lookbook.title")
        //navMyProfileController.tabBarItem.accessibilityLabel = String(localized: "auth.signup.title")
        
        setViewControllers([navClothesController, navOutfitsController], animated: false)
    }
}
