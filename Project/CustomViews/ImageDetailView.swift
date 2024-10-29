//
//  ImageDetailView.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 23/10/2024.
//

import Foundation
import UIKit
import Photos

// MARK: - ImageDetailViewDelegate
protocol ImageDetailViewDelegate: AnyObject {
    func imageDetailViewDidRequestDismiss(_ view: ImageDetailView)
}

// MARK: - ImageDetailView
class ImageDetailView: UIView {
    // MARK: - Properties
    
    private var image: AppMedia
    private var initialTouchPoint: CGPoint = .zero
    private let dismissThreshold: CGFloat = 100
    private var imageViewTopConstraint: NSLayoutConstraint?
    weak var delegate: ImageDetailViewDelegate?
    
    // MARK: - UI Elements
    
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = DefaultValue.Colors.accentColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    
    init(image: AppMedia) {
        self.image = image
        super.init(frame: .zero)
        setupUI()
        loadImage()
        backgroundColor = DefaultValue.Colors.secondaryColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        
        addSubview(imageView)
        addSubview(closeButton)
        
        imageViewTopConstraint = imageView.topAnchor.constraint(equalTo: topAnchor)
        
        NSLayoutConstraint.activate([
            imageViewTopConstraint!,
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        imageView.addGestureRecognizer(pinchGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        imageView.addGestureRecognizer(panGesture)
        
        imageView.isUserInteractionEnabled = true
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }
    
    private func loadImage() {
        guard let localIdentifier = image.localIdentifier else {
            print("Error: Video local identifier is nil")
            return
        }

        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = fetchResult.firstObject else {
            print("Error: No asset found with the provided local identifier")
            return
        }

        let imageManager = PHImageManager.default()
        let targetSize = CGSize(width: bounds.width, height: bounds.height)
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true

        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { [weak self] (result, info) in
            DispatchQueue.main.async {
                if let resultImage = result {
                    self?.imageView.image = resultImage
                } else {
                    print("Error: Failed to load image for asset with local identifier: \(localIdentifier)")
                }
            }
        }
    }
}

// MARK: - Actions
extension ImageDetailView {
    
    @objc private func closeTapped() {
        delegate?.imageDetailViewDidRequestDismiss(self)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began || gesture.state == .changed {
            imageView.transform = imageView.transform.scaledBy(
                x: gesture.scale,
                y: gesture.scale
            )
            gesture.scale = 1.0
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let touchPoint = gesture.translation(in: self)
        
        switch gesture.state {
        case .began:
            initialTouchPoint = touchPoint
            
        case .changed:
            if touchPoint.y >= 0 {
                imageViewTopConstraint?.constant = touchPoint.y
                
                let progress = min(1.0, touchPoint.y / dismissThreshold)
                backgroundColor = DefaultValue.Colors.secondaryColor.withAlphaComponent(1 - progress * 0.6)
            }
            
        case .ended:
            let velocity = gesture.velocity(in: self)
            
            if touchPoint.y > dismissThreshold || velocity.y > 1000 {
                // Notify delegate to handle dismiss
                delegate?.imageDetailViewDidRequestDismiss(self)
            } else {
                UIView.animate(withDuration: 0.3) { [weak self] in
                    self?.imageViewTopConstraint?.constant = 0
                    self?.backgroundColor = DefaultValue.Colors.secondaryColor
                    self?.layoutIfNeeded()
                }
            }
            
        default:
            break
        }
    }
}
