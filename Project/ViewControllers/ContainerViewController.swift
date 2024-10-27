//
//  ContainerViewController.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 14/10/2024.
//

import Foundation
import UIKit

class ContainerViewController: UIViewController {
    
    // MARK: - Properties
    
    private let sideMenuController = SideMenuController()
    private let homeViewController = HomeViewController()
    private var navVC: UINavigationController?
    
    private let menuWidth: CGFloat = UIScreen.main.bounds.width * 0.8
    private var menuState: MenuState = .closed
    
    private enum MenuState {
        case opened, closed
    }
    
    // MARK: - UI Elements
    
    private lazy var blurView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.alpha = 0
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapBlurView))
        view.addGestureRecognizer(tapGesture)
        return view
    }()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupChildViewControllers()
        setupGestures()
    }
}

// MARK: - HomeViewControllerDelegate
extension ContainerViewController: HomeViewControllerDelegate {
    func didTapMenuButton() {
        toggleMenu(shouldOpen: menuState == .closed)
    }
}

// MARK: - SideMenuControllerDelegate
extension ContainerViewController: SideMenuControllerDelegate {
    func closeButtonTapped() {
        toggleMenu(shouldOpen: false)
    }
}

// MARK: - Setup
extension ContainerViewController {
    
    // MARK: - Setup Methods
    
    private func setupChildViewControllers() {
        setupDelegates()
        setupNavigationController()
        setupBlurView()
        setupSideMenu()
    }
    
    private func setupDelegates() {
        homeViewController.delegate = self
        sideMenuController.delegate = self
    }
    
    private func setupNavigationController() {
        let navVC = UINavigationController(rootViewController: homeViewController)
        addChild(navVC)
        view.addSubview(navVC.view)
        navVC.didMove(toParent: self)
        self.navVC = navVC
    }
    
    private func setupBlurView() {
        view.addSubview(blurView)
        blurView.frame = view.bounds
    }
    
    private func setupSideMenu() {
        addChild(sideMenuController)
        view.addSubview(sideMenuController.view)
        sideMenuController.didMove(toParent: self)
        sideMenuController.view.frame = CGRect(x: -menuWidth, y: 0, width: menuWidth, height: view.bounds.height)
    }
    
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPanGesture(_:)))
        view.addGestureRecognizer(panGesture)
    }
    
}

// MARK: - Menu Handling Methods
extension ContainerViewController {
    
    // MARK: - Menu Handling Methods
    
    private func toggleMenu(shouldOpen: Bool) {
        guard canToggleMenu() else { return }
        
        let menuXPosition = shouldOpen ? 0 : -menuWidth
        let navVCXPosition = shouldOpen ? menuWidth : 0
        let blurAlpha: CGFloat = shouldOpen ? 1 : 0
        
        UIView.animate(
            withDuration: 1,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: .curveEaseInOut
        ) {
            self.sideMenuController.view.frame.origin.x = menuXPosition
            self.navVC?.view.frame.origin.x = navVCXPosition
            self.blurView.alpha = blurAlpha
        } completion: { done in
            if done {
                self.menuState = shouldOpen ? .opened : .closed
            }
        }
    }
    
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
    
    private func handlePanEnded(_ translation: CGPoint) {
        guard canToggleMenu() else { return }
        
        let shouldOpen = (menuState == .closed && translation.x > view.bounds.width * 0.4) ||
            (menuState == .opened && translation.x > -view.bounds.width * 0.4)
        toggleMenu(shouldOpen: shouldOpen)
    }
    
    private func canToggleMenu() -> Bool {
        guard let topViewController = navVC?.topViewController else { return false }
        return topViewController is HomeViewController
    }
    
}

// MARK: - Action Methods
extension ContainerViewController {
    
    // MARK: - Action Methods
    
    @objc private func didTapBlurView() {
        toggleMenu(shouldOpen: false)
    }
    
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
