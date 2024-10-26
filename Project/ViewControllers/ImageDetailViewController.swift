//
//  ImageDetailViewController.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 23/10/2024.
//

import Foundation
import UIKit
import Photos

// MARK: - ImageDetailViewController.swift

class ImageDetailViewController: UIViewController {
    // MARK: - Properties
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var image: AppImage
    private var initialTouchPoint: CGPoint = .zero
    private let dismissThreshold: CGFloat = 100
    private var imageViewTopConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    init(image: AppImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = nil
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.tintColor = .black
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        navigationItem.rightBarButtonItem = closeButton
        
        view.addSubview(imageView)
        imageViewTopConstraint = imageView.topAnchor.constraint(equalTo: view.topAnchor)
        
        NSLayoutConstraint.activate([
            imageViewTopConstraint!,
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        imageView.addGestureRecognizer(pinchGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        imageView.addGestureRecognizer(panGesture)
        
        imageView.isUserInteractionEnabled = true
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
        let targetSize = CGSize(width: imageView.bounds.width, height: imageView.bounds.height)
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
    
    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
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
        let touchPoint = gesture.translation(in: view)
        
        switch gesture.state {
        case .began:
            initialTouchPoint = touchPoint
            
        case .changed:
            if touchPoint.y >= 0 {
                imageViewTopConstraint?.constant = touchPoint.y
                
                let progress = min(1.0, touchPoint.y / dismissThreshold)
                view.backgroundColor = UIColor.white.withAlphaComponent(1 - progress * 0.6)
            }
            
        case .ended:
            let velocity = gesture.velocity(in: view)
            
            if touchPoint.y > dismissThreshold || velocity.y > 1000 {
                // Animate dismiss
                UIView.animate(withDuration: 0.3, animations: { [weak self] in
                    guard let self = self else { return }
                    self.imageViewTopConstraint?.constant = self.view.frame.height
                    self.view.backgroundColor = .clear
                }) { [weak self] _ in
                    self?.dismiss(animated: false)
                }
            } else {
                UIView.animate(withDuration: 0.3) { [weak self] in
                    self?.imageViewTopConstraint?.constant = 0
                    self?.view.backgroundColor = .white
                    self?.view.layoutIfNeeded()
                }
            }
            
        default:
            break
        }
    }
}
