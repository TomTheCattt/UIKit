//
//  UINavigationViewControllerExtension.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 29/10/2024.
//

import Foundation
import UIKit

extension UINavigationController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        appearance.backgroundColor = DefaultValue.Colors.sideMenuBackgroundColor
        appearance.titleTextAttributes = [
            .foregroundColor: DefaultValue.Colors.accentColor,
            .font: DefaultValue.Fonts.titleFont
        ]
        
        appearance.shadowColor = .clear
        
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        
        if #available(iOS 15.0, *) {
            navigationBar.compactScrollEdgeAppearance = appearance
        }
        
        // Các thiết lập khác
        navigationBar.tintColor = DefaultValue.Colors.accentColor
        navigationBar.isTranslucent = false
        
        // Điều chỉnh chiều cao bao gồm safe area
        let window = UIApplication.shared.windows.first
        let topPadding = window?.safeAreaInsets.top ?? 0
        navigationBar.frame.size.height = 44 + topPadding
    }
}
