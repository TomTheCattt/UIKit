import Foundation
import UIKit

// MARK: - UINavigationController Extension
/// An extension for `UINavigationController` that customizes the appearance of the navigation bar.
extension UINavigationController {
    
    /// Configures the navigation bar's appearance when the view is loaded.
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
        
        // Configure additional navigation bar properties
        navigationBar.tintColor = DefaultValue.Colors.accentColor
        navigationBar.isTranslucent = false
        
        // Adjust the height of the navigation bar to include safe area insets
        if let windowScene = view.window?.windowScene {
            let topPadding = windowScene.statusBarManager?.statusBarFrame.height ?? 0
            navigationBar.frame.size.height = 44 + topPadding
        }
    }
}
