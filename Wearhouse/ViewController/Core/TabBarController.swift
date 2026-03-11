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
        //let MyProfileController = OutfitComposerViewController()
        
        //let navHomeController = UINavigationController(rootViewController: HomeController)
        let navClothesController = UINavigationController(rootViewController: ClothesController)
        let navOutfitsController = UINavigationController(rootViewController: OutfitsController)
        //let navMyProfileController = UINavigationController(rootViewController: MyProfileController)
        
        //navHomeController.tabBarItem = UITabBarItem(title: "home", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))
        navClothesController.tabBarItem = UITabBarItem(title: String(localized: "wardrobe.title"), image: UIImage(systemName: "tshirt"), selectedImage: UIImage(systemName: "tshirt.fill"))
        navOutfitsController.tabBarItem = UITabBarItem(title: String(localized: "lookbook.title"), image: UIImage(systemName: "cabinet"), selectedImage: UIImage(systemName: "cabinet.fill"))
        //navMyProfileController.tabBarItem = UITabBarItem(title: "profile", image: UIImage(systemName: "person"), selectedImage: UIImage(systemName: "person.fill"))
        
        //tabBar.tintColor = .label
        //tabBar.backgroundColor = .background
        
        setViewControllers([navClothesController, navOutfitsController], animated: false)
    }
}
