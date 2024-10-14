//
//  URLInputView.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 14/10/2024.
//

import Foundation
import UIKit

class URLInputView: UIView {
    
    weak var delegate: URLInputViewDelegate?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter URL"
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 18)
        return label
    }()
    
    private let urlTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "https://example.com/media.jpg"
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = .URL
        return textField
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.addTarget(URLInputView.self, action: #selector(saveButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.addTarget(URLInputView.self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 10
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        
        addSubview(titleLabel)
        addSubview(urlTextField)
        addSubview(saveButton)
        addSubview(cancelButton)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        urlTextField.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            urlTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            urlTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            urlTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            saveButton.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: centerXAnchor, constant: -8),
            
            cancelButton.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 16),
            cancelButton.leadingAnchor.constraint(equalTo: centerXAnchor, constant: 8),
            
            bottomAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 16)
        ])
    }
    
    @objc private func saveButtonTapped() {
        guard let urlString = urlTextField.text, !urlString.isEmpty else {
            // Show an alert or handle empty input
            return
        }
        delegate?.urlInputView(self, didEnterURL: urlString)
    }
    
    @objc private func cancelButtonTapped() {
        delegate?.urlInputViewDidCancel(self)
    }
}
