//
//  SideMenuController.swift
//  UIKitProject
//
//  Created by Việt Anh Nguyễn on 02/10/2024.
//

import UIKit

/// Controller for the side menu UI
class SideMenuController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: SideMenuControllerDelegate?
    
    private let settingOptions = ["Rate Us", "Share App", "Feedback", "Term Of Policy"]
    
    // MARK: - UI Elements
    
    private lazy var settingsLabel: UILabel = {
        let label = UILabel()
        label.text = "Settings"
        label.font = .boldSystemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var arrowButton: UIButton = {
        let button = UIButton(type: .system)
        let boldConfig = UIImage.SymbolConfiguration(weight: .bold)
        let image = UIImage(systemName: "chevron.right", withConfiguration: boldConfig)
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var optionButtons: [UIButton] = {
        return settingOptions.map { option in
            let button = UIButton(type: .system)
            button.setTitle(option, for: .normal)
            button.backgroundColor = .clear
            button.setTitleColor(.black, for: .normal)
            button.titleLabel?.textAlignment = .center
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }
    }()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        view.backgroundColor = .systemPink
        
        view.addSubview(settingsLabel)
        view.addSubview(arrowButton)
        optionButtons.forEach { view.addSubview($0) }
    }
    
    private func setupConstraints() {
        setupHeaderConstraints()
        setupOptionButtonsConstraints()
    }
    
    private func setupHeaderConstraints() {
        NSLayoutConstraint.activate([
            settingsLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            settingsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            arrowButton.centerYAnchor.constraint(equalTo: settingsLabel.centerYAnchor),
            arrowButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupOptionButtonsConstraints() {
        var previousButton: UIButton?
        
        for button in optionButtons {
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                button.heightAnchor.constraint(equalToConstant: 50)
            ])
            
            if let previousButton = previousButton {
                button.topAnchor.constraint(equalTo: previousButton.bottomAnchor, constant: 15).isActive = true
            } else {
                button.topAnchor.constraint(equalTo: settingsLabel.bottomAnchor, constant: 20).isActive = true
            }
            
            previousButton = button
        }
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        delegate?.closeButtonTapped()
    }
}



