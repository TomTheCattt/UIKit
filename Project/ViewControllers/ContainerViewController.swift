import Foundation
import UIKit

/// A view controller that manages a side menu and a home view controller.
class ContainerViewController: UIViewController {
    
    // MARK: - Properties
    
    private let sideMenuController = SideMenuController()
    private let homeViewController = HomeViewController()
    private var navVC: UINavigationController?
    
    /// The width of the side menu based on the current orientation.
    private var menuWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return isPortrait ? screenWidth * 0.8 : screenWidth * 0.4
    }
    
    /// Indicates whether the device is in portrait orientation.
    private var isPortrait: Bool {
        return UIDevice.current.orientation.isPortrait || UIDevice.current.orientation == .unknown
    }
    
    /// The current state of the side menu.
    private var menuState: MenuState = .closed
    
    /// Enum representing the state of the side menu.
    private enum MenuState {
        case opened, closed
    }
    
    // MARK: - UI Elements
    
    /// A view that adds a blur effect behind the side menu.
    private lazy var blurView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.alpha = 0
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapBlurView))
        view.addGestureRecognizer(tapGesture)
        return view
    }()
    
    // MARK: - Lifecycle Methods
    
    /// Called after the controller's view is loaded into memory.
    override func viewDidLoad() {
        super.viewDidLoad()
        setupChildViewControllers()
        setupGestures()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationDidChange),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }
    
    /// Deinitializes the view controller and removes observers.
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - HomeViewControllerDelegate
extension ContainerViewController: HomeViewControllerDelegate {
    
    /// Handles the menu button tap event.
    func didTapMenuButton() {
        toggleMenu(shouldOpen: menuState == .closed)
    }
}

// MARK: - SideMenuControllerDelegate
extension ContainerViewController: SideMenuControllerDelegate {
    
    /// Handles the close button tap event in the side menu.
    func closeButtonTapped() {
        toggleMenu(shouldOpen: false)
    }
}

// MARK: - Setup
extension ContainerViewController {
    
    // MARK: - Setup Methods
    
    /// Sets up child view controllers and their delegates.
    private func setupChildViewControllers() {
        setupDelegates()
        setupNavigationController()
        setupBlurView()
        setupSideMenu()
    }
    
    /// Sets up delegates for child view controllers.
    private func setupDelegates() {
        homeViewController.delegate = self
        sideMenuController.delegate = self
    }
    
    /// Sets up the navigation controller for the home view controller.
    private func setupNavigationController() {
        let navVC = UINavigationController(rootViewController: homeViewController)
        navVC.navigationBar.isTranslucent = false
        addChild(navVC)
        view.addSubview(navVC.view)
        navVC.didMove(toParent: self)
        self.navVC = navVC
    }
    
    /// Sets up the blur view behind the side menu.
    private func setupBlurView() {
        view.addSubview(blurView)
        updateBlurViewFrame()
    }
    
    /// Updates the frame of the blur view to match the parent view's bounds.
    private func updateBlurViewFrame() {
        blurView.frame = view.bounds
    }
    
    /// Sets up the side menu view controller.
    private func setupSideMenu() {
        sideMenuController.view.frame = CGRect(x: -menuWidth, y: 0, width: menuWidth, height: view.bounds.height)
        addChild(sideMenuController)
        view.addSubview(sideMenuController.view)
        sideMenuController.didMove(toParent: self)
    }
    
    /// Sets up gesture recognizers for the container view.
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPanGesture(_:)))
        view.addGestureRecognizer(panGesture)
    }
    
    /// Updates the frame of the side menu based on its state.
    private func updateSideMenuFrame(for state: MenuState) {
        let xPosition: CGFloat = state == .closed ? -menuWidth : 0
        sideMenuController.view.frame = CGRect(x: xPosition,
                                               y: 0,
                                               width: menuWidth,
                                               height: view.bounds.height)
    }
    
    /// Updates the frame of the navigation controller based on the menu state.
    private func updateNavControllerFrame(for state: MenuState) {
        let xPosition: CGFloat = state == .closed ? 0 : menuWidth
        navVC?.view.frame = CGRect(x: xPosition,
                                   y: 0,
                                   width: view.bounds.width,
                                   height: view.bounds.height)
    }
}

// MARK: - Orientation Handling
extension ContainerViewController {
    
    /// Responds to device orientation changes.
    @objc private func orientationDidChange() {
        // Wait briefly for the system to complete the orientation change
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            self.updateBlurViewFrame()
            self.updateSideMenuFrame(for: self.menuState)
            self.updateNavControllerFrame(for: self.menuState)
        }
    }
}

// MARK: - Menu Handling Methods
extension ContainerViewController {
    
    // MARK: - Menu Handling Methods
    
    /// Toggles the side menu open or closed based on the specified state.
    /// - Parameter shouldOpen: A boolean indicating whether the menu should open or close.
    private func toggleMenu(shouldOpen: Bool) {
        guard canToggleMenu() else { return }
        
        let targetState: MenuState = shouldOpen ? .opened : .closed
        let blurAlpha: CGFloat = shouldOpen ? 1 : 0
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: .curveEaseInOut
        ) {
            self.updateSideMenuFrame(for: targetState)
            self.updateNavControllerFrame(for: targetState)
            self.blurView.alpha = blurAlpha
        } completion: { done in
            if done {
                self.menuState = targetState
            }
        }
    }
    
    /// Handles the pan gesture when the user moves their finger.
    /// - Parameter translation: The translation of the pan gesture.
    private func handlePanChanged(_ translation: CGPoint) {
        guard canToggleMenu() else { return }
        
        if menuState == .closed && translation.x > 0 {
            navVC?.view.frame.origin.x = min(translation.x, menuWidth)
            sideMenuController.view.frame.origin.x = min(translation.x - menuWidth, 0)
            blurView.alpha = min(translation.x / menuWidth, 1)
        } else if menuState == .opened && translation.x < 0 {
            navVC?.view.frame.origin.x = max(menuWidth + translation.x, 0)
            sideMenuController.view.frame.origin.x = max(translation.x, -menuWidth)
            blurView.alpha = max(1 + translation.x / menuWidth, 0)
        }
    }
    
    /// Handles the end of the pan gesture and determines if the menu should open or close.
    /// - Parameter translation: The translation of the pan gesture.
    private func handlePanEnded(_ translation: CGPoint) {
        guard canToggleMenu() else { return }
        
        let shouldOpen = (menuState == .closed && translation.x > menuWidth * 0.5) ||
        (menuState == .opened && translation.x > -menuWidth * 0.5)
        toggleMenu(shouldOpen: shouldOpen)
    }
    
    /// Checks if the menu can be toggled based on the top view controller.
    /// - Returns: A boolean indicating if the menu can be toggled.
    private func canToggleMenu() -> Bool {
        guard let topViewController = navVC?.topViewController else { return false }
        return topViewController is HomeViewController
    }
}

// MARK: - Action Methods
extension ContainerViewController {
    
    // MARK: - Action Methods
    
    /// Handles taps on the blur view to close the menu.
    @objc private func didTapBlurView() {
        toggleMenu(shouldOpen: false)
    }
    
    /// Handles pan gesture events to open or close the menu.
    /// - Parameter recognizer: The pan gesture recognizer.
    @objc private func didPanGesture(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: view)
        
        switch recognizer.state {
        case .changed:
            handlePanChanged(translation)
        case .ended:
            handlePanEnded(translation)
        default:
            break
        }
    }
}
