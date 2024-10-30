//
//  SideMenuView.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 30/10/2024.
//

import Foundation
import UIKit

class SideMenuView: UIView {
    // MARK: - Properties
    weak var delegate: SideMenuViewDelegate?
    private let settingOptions = DefaultValue.String.settingsOptions
    
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
    
    private lazy var optionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup
extension SideMenuView {
    private func setupViews() {
        backgroundColor = DefaultValue.Colors.sideMenuBackgroundColor
        addSubview(settingsLabel)
        addSubview(arrowButton)
        addSubview(optionsStackView)
        
        optionButtons.forEach { optionsStackView.addArrangedSubview($0) }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            settingsLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            arrowButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            arrowButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            optionsStackView.topAnchor.constraint(equalTo: settingsLabel.bottomAnchor),
            settingsLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            optionsStackView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        ])
    }
}

// MARK: - Actions
extension SideMenuView {
    @objc private func backButtonTapped() {
        delegate?.closeButtonTapped()
    }
}

// MARK: - Delegate
protocol SideMenuViewDelegate: AnyObject {
    func closeButtonTapped()
}


