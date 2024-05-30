//
//  MainTabBarController.swift
//  PhotoSearch
//
//  Created by Smbat Tumasyan on 30.05.24.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    // MARK: - Life Cyrcle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the unselected item color to white (or any color you prefer)
        tabBar.unselectedItemTintColor = .white
        
        // Set the selected item color to yellow (or any color you prefer)
        tabBar.tintColor = .green
        
        // Add a blur effect to the tab bar background
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = tabBar.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Insert the blur effect view below the tab bar items
        tabBar.insertSubview(blurEffectView, at: 0)
        
        let photosVC = PhotosViewController()
        photosVC.tabBarItem = UITabBarItem(title: "Photos", image: UIImage(systemName: "photo"), tag: 0)
        
        let favoritesVC = FavoritesViewController()
        favoritesVC.tabBarItem = UITabBarItem(title: "Favorites", image: UIImage(systemName: "heart"), tag: 1)
        
        viewControllers = [
            UINavigationController(rootViewController: photosVC),
            UINavigationController(rootViewController: favoritesVC)
        ]
    }
}
