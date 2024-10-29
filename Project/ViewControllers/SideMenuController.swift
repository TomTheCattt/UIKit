//
//  SideMenuController.swift
//  UIKitProject
//
//  Created by Việt Anh Nguyễn on 02/10/2024.
//

import UIKit

class SideMenuController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: SideMenuControllerDelegate?
    
    private let settingOptions = DefaultValue.String.settingsOptions
    
    // MARK: - Constraints
    private var topConstraint: NSLayoutConstraint?
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    private var containerWidthConstraint: NSLayoutConstraint?
    private var containerCenterXConstraint: NSLayoutConstraint?
    private var containerLeadingConstraint: NSLayoutConstraint?
    private var containerTrailingConstraint: NSLayoutConstraint?
    
    // MARK: - UI Elements
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var settingsLabel: UILabel = {
        let label = UILabel()
        label.text = DefaultValue.String.sideMenuTitle.uppercased()
        label.font = .boldSystemFont(ofSize: DefaultValue.FontSizes.titleFontSize)
        label.font = DefaultValue.Fonts.titleFont
        label.textColor = DefaultValue.Colors.accentColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var arrowButton: UIButton = {
        let button = UIButton(type: .system)
        let boldConfig = UIImage.SymbolConfiguration(weight: .bold)
        let image = UIImage(systemName: DefaultValue.Icon.chevronRightIcon, withConfiguration: boldConfig)
        button.setImage(image, for: .normal)
        button.tintColor = DefaultValue.Colors.accentColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var optionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var optionButtons: [UIButton] = {
        return settingOptions.map { option in
            let button = UIButton(type: .system)
            button.setTitle(option, for: .normal)
            button.backgroundColor = .clear
            button.titleLabel?.font = DefaultValue.Fonts.bodyFont
            button.setTitleColor(DefaultValue.Colors.accentColor, for: .normal)
            button.contentHorizontalAlignment = .center
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupInitialConstraints()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateLayoutForCurrentOrientation()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass ||
           traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass {
            updateLayoutForCurrentOrientation()
        }
    }
}

// MARK: - SideMenuController Setup

extension SideMenuController {
    
    // MARK: - Setup Methods
    private func setupView() {
        view.backgroundColor = DefaultValue.Colors.sideMenuBackgroundColor
        view.addSubview(containerView)
        containerView.addSubview(settingsLabel)
        containerView.addSubview(arrowButton)
        containerView.addSubview(optionsStackView)
        
        optionButtons.forEach { optionsStackView.addArrangedSubview($0) }
    }
    
    private func setupInitialConstraints() {
        let safeArea = view.safeAreaLayoutGuide
        
        // Container view base constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
        
        // Create container edge constraints
        containerLeadingConstraint = containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        containerTrailingConstraint = containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        
        // Header constraints
        NSLayoutConstraint.activate([
            settingsLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            arrowButton.centerYAnchor.constraint(equalTo: settingsLabel.centerYAnchor),
            arrowButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
        ])
        
        // Options stack view constraints
        NSLayoutConstraint.activate([
            optionsStackView.topAnchor.constraint(equalTo: settingsLabel.bottomAnchor, constant: 30),
            optionsStackView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -20)
        ])
        
        // Set height constraint for option buttons
        optionButtons.forEach { button in
            button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
        
        // Store constraints that will be updated based on orientation
        topConstraint = settingsLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20)
        leadingConstraint = optionsStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20)
        trailingConstraint = optionsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
        
        // Activate initial constraints
        topConstraint?.isActive = true
        leadingConstraint?.isActive = true
        trailingConstraint?.isActive = true
    }
    
    private func updateLayoutForCurrentOrientation() {
        // Deactivate all orientation-specific constraints
        containerWidthConstraint?.isActive = false
        containerCenterXConstraint?.isActive = false
        containerLeadingConstraint?.isActive = false
        containerTrailingConstraint?.isActive = false
        
        let isLandscape = UIDevice.current.orientation.isLandscape
        let screenWidth = view.bounds.width
        let screenHeight = view.bounds.height
        
        if isLandscape {
            // In landscape, use fixed width and center
            let maxWidth = min(screenWidth * 0.7, 500.0)
            containerWidthConstraint = containerView.widthAnchor.constraint(equalToConstant: maxWidth)
            containerCenterXConstraint = containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            
            containerWidthConstraint?.isActive = true
            containerCenterXConstraint?.isActive = true
        } else {
            // In portrait, use edge constraints
            containerLeadingConstraint?.isActive = true
            containerTrailingConstraint?.isActive = true
        }
        
        // Update spacing based on screen size
        let topSpacing = min(screenHeight * 0.05, 30.0)
        let sideSpacing = min(screenWidth * 0.05, 20.0)
        
        // Update existing constraints
        topConstraint?.constant = topSpacing
        leadingConstraint?.constant = sideSpacing
        trailingConstraint?.constant = -sideSpacing
        
        // Update stack view spacing
        optionsStackView.spacing = min(screenHeight * 0.02, 15.0)
        
        view.layoutIfNeeded()
    }
}

// MARK: - SideMenuController Actions

extension SideMenuController {
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        delegate?.closeButtonTapped()
    }
}
