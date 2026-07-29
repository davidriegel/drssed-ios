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
        let ClothesController = ClothesGalleryController()
        let OutfitsController = OutfitsGalleryViewController()
        let ProfileController = ProfileViewController()

        HomeController.title = String(localized: "home.title")
        ClothesController.title = String(localized: "wardrobe.title")
        OutfitsController.title = String(localized: "lookbook.title")
        ProfileController.title = String(localized: "profile.title")

        let navHomeController = UINavigationController(rootViewController: HomeController)
        let navClothesController = UINavigationController(rootViewController: ClothesController)
        let navOutfitsController = UINavigationController(rootViewController: OutfitsController)
        let navProfileController = UINavigationController(rootViewController: ProfileController)

        navHomeController.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))
        navClothesController.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "tshirt"), selectedImage: UIImage(systemName: "tshirt.fill"))
        navOutfitsController.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "cabinet"), selectedImage: UIImage(systemName: "cabinet.fill"))
        navProfileController.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "person"), selectedImage: UIImage(systemName: "person.fill"))

        navHomeController.tabBarItem.accessibilityLabel = String(localized: "home.title")
        navClothesController.tabBarItem.accessibilityLabel = String(localized: "wardrobe.title")
        navOutfitsController.tabBarItem.accessibilityLabel = String(localized: "lookbook.title")
        navProfileController.tabBarItem.accessibilityLabel = String(localized: "profile.title")

        setViewControllers([navHomeController, navClothesController, navOutfitsController, navProfileController], animated: false)
    }
}
