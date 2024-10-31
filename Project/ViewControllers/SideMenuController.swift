import UIKit

/// A view controller that manages the side menu interface and its interactions.
class SideMenuController: UIViewController {
    
    // MARK: - Properties
    /// A delegate that communicates user interactions with the side menu.
    weak var delegate: SideMenuControllerDelegate?
    
    /// The view that displays the side menu.
    private let sideMenuView = SideMenuView()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(sideMenuView)
        sideMenuView.frame = view.bounds
        sideMenuView.setOptions(DefaultValue.String.settingsOptions) // Pass settings options to the view
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        sideMenuView.frame = view.bounds // Update the frame for any layout changes
    }
}

// MARK: - SideMenuController Actions
extension SideMenuController {
    
    /// Handles the action for the back button tap.
    @objc private func backButtonTapped() {
        delegate?.closeButtonTapped()
    }
}
