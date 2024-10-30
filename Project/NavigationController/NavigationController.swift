//
//  NavigationController.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 30/10/2024.
//

import Foundation
import UIKit

class NavigationController: UINavigationController {
    private let homeViewController: HomeViewController
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
            self.homeViewController = HomeViewController()
            super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
            setupControllers()
        }
    
    private func setupControllers() {
        viewControllers = [homeViewController]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
