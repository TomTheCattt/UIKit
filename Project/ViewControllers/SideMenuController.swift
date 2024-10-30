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
        //updateLayoutForCurrentOrientation()
    }
    
//    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        super.traitCollectionDidChange(previousTraitCollection)
//        if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass ||
//            traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass {
//            updateLayoutForCurrentOrientation()
//        }
//    }
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
        
        // Container view constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Header constraints
        NSLayoutConstraint.activate([
            settingsLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            settingsLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            arrowButton.centerYAnchor.constraint(equalTo: settingsLabel.centerYAnchor),
            arrowButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
        ])
        
        // Options stack view constraints with fixed margins
        NSLayoutConstraint.activate([
            optionsStackView.topAnchor.constraint(equalTo: settingsLabel.bottomAnchor, constant: 30),
            optionsStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            optionsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            optionsStackView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -20)
        ])
        
        // Set height constraint for option buttons
        optionButtons.forEach { button in
            button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
    }
    
    private func updateLayoutForCurrentOrientation() {
            // Deactivate previous constraints
            containerWidthConstraint?.isActive = false
            leadingConstraint?.isActive = false
            trailingConstraint?.isActive = false
            
            let isLandscape = UIDevice.current.orientation.isLandscape
            let safeArea = view.safeAreaLayoutGuide
            
            if isLandscape {
                // Landscape layout
                let maxWidth = min(view.bounds.width * 0.7, 500.0)
                
                // Width constraint
                containerWidthConstraint = containerView.widthAnchor.constraint(equalToConstant: maxWidth)
                
                // Center horizontally
                leadingConstraint = containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
                
                // Activate landscape constraints
                NSLayoutConstraint.activate([
                    containerWidthConstraint!,
                    leadingConstraint!,
                    containerView.topAnchor.constraint(equalTo: safeArea.topAnchor),
                    containerView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
                ])
                
                // Update stack view spacing for landscape
                optionsStackView.spacing = 12
                
            } else {
                // Portrait layout
                // Container takes full width with margins
                leadingConstraint = containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
                trailingConstraint = containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
                
                // Activate portrait constraints
                NSLayoutConstraint.activate([
                    leadingConstraint!,
                    trailingConstraint!,
                    containerView.topAnchor.constraint(equalTo: safeArea.topAnchor),
                    containerView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
                ])
                
                // Update stack view spacing for portrait
                optionsStackView.spacing = 15
            }
            
            // Update UI elements for current orientation
            updateUIForCurrentOrientation(isLandscape: isLandscape)
            
            // Force layout update
            view.layoutIfNeeded()
        }
        
        private func updateUIForCurrentOrientation(isLandscape: Bool) {
            if isLandscape {
                // Landscape UI adjustments
                settingsLabel.font = .boldSystemFont(ofSize: DefaultValue.FontSizes.titleFontSize - 2)
                optionButtons.forEach { button in
                    button.titleLabel?.font = DefaultValue.Fonts.bodyFont.withSize(DefaultValue.FontSizes.bodyFontSize - 1)
                }
            } else {
                // Portrait UI adjustments
                settingsLabel.font = .boldSystemFont(ofSize: DefaultValue.FontSizes.titleFontSize)
                optionButtons.forEach { button in
                    button.titleLabel?.font = DefaultValue.Fonts.bodyFont
                }
            }
        }
}

// MARK: - SideMenuController Actions
extension SideMenuController {
    @objc private func backButtonTapped() {
        delegate?.closeButtonTapped()
    }
}
