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
        let ClothesController = ClothesGalleryController()
        let OutfitsController = OutfitsGalleryViewController()
        let ProfileController = ProfileViewController()
        
        ClothesController.title = String(localized: "wardrobe.title")
        OutfitsController.title = String(localized: "lookbook.title")
        ProfileController.title = String(localized: "profile.title")
        
        let navClothesController = UINavigationController(rootViewController: ClothesController)
        let navOutfitsController = UINavigationController(rootViewController: OutfitsController)
        let navProfileController = UINavigationController(rootViewController: ProfileController)
        
        navClothesController.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "tshirt"), selectedImage: UIImage(systemName: "tshirt.fill"))
        navOutfitsController.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "cabinet"), selectedImage: UIImage(systemName: "cabinet.fill"))
        navProfileController.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "person"), selectedImage: UIImage(systemName: "person.fill"))
        
        navClothesController.tabBarItem.accessibilityLabel = String(localized: "wardrobe.title")
        navOutfitsController.tabBarItem.accessibilityLabel = String(localized: "lookbook.title")
        navProfileController.tabBarItem.accessibilityLabel = String(localized: "profile.title")
        
        setViewControllers([navClothesController, navOutfitsController, navProfileController], animated: false)
    }
}
