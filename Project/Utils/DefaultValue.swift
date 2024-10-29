//
//  DefaultValue.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 29/10/2024.
//

import Foundation
import UIKit

struct DefaultValue {
    // MARK: - Colors
    struct Colors {
        static let sideMenuBackgroundColor = UIColor(hex: "#101432")
        static let primaryColor = UIColor(hex: "#94A3FF")
        static let secondaryColor = UIColor(hex: "#171723")
        static let accentColor = UIColor(hex: "#FFFFFF")
        static let footnoteColor = UIColor(hex: "#8E8E8E")
        // Add more colors as needed
    }
    
    // MARK: - Font Sizes
    struct FontSizes {
        static let titleFontSize: CGFloat = 24
        static let subtitleFontSize: CGFloat = 18
        static let bodyFontSize: CGFloat = 16
    }
    
    // MARK: - Fonts
    struct Fonts {
        static let titleFont = UIFont.systemFont(ofSize: FontSizes.titleFontSize, weight: .bold)
        static let bodyFont = UIFont.systemFont(ofSize: FontSizes.bodyFontSize)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let smallSpacing: CGFloat = 8
        static let mediumSpacing: CGFloat = 16
        static let largeSpacing: CGFloat = 24
    }
    // MARK: - String
    struct String {
        static let settingsOptions = ["Rate Us", "Share App", "Feedback", "Term Of Policy"]
        static let sideMenuTitle = "Settings"
        static let homeViewTitle = "Play Photos"
        static let imageViewTitle = "All Images"
        static let videoViewTitle = "All Videos"
    }
    // MARK: - Icon
    struct Icon {
        static let settingsIcon = "setting"
        static let chevronRightIcon = "chevron.right"
        static let threeLineHorizontalIcon = "line.horizontal.3"
        static let reloadIcon = "arrow.clockwise"
    }
}

// MARK: - UIColor Extension for Hex
extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexFormatted: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexFormatted.hasPrefix("#") {
            hexFormatted.remove(at: hexFormatted.startIndex)
        }
        assert(hexFormatted.count == 6, "Invalid hex code")
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)
        
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension UIFont {
    func bold() -> UIFont {
            return UIFont(descriptor: self.fontDescriptor.withSymbolicTraits(.traitBold) ?? self.fontDescriptor, size: 0)
        }
}
