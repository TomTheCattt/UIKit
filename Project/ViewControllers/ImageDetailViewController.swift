//
//  ImageDetailViewController.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 23/10/2024.
//

import Foundation
import UIKit

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
    private let dismissThreshold: CGFloat = 100 // Ngưỡng để dismiss view
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
        
        // Setup image view với top constraint có thể thay đổi
        view.addSubview(imageView)
        imageViewTopConstraint = imageView.topAnchor.constraint(equalTo: view.topAnchor)
        
        NSLayoutConstraint.activate([
            imageViewTopConstraint!,
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Setup pinch gesture
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        imageView.addGestureRecognizer(pinchGesture)
        
        // Setup pan gesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        imageView.addGestureRecognizer(panGesture)
        
        // Enable user interaction
        imageView.isUserInteractionEnabled = true
    }
    
    private func loadImage() {
        guard let filepath = image.filepath, !filepath.isEmpty else {
            print("Invalid image file path")
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                guard let thumbnailData = self?.image.thumbnail else {
                    print("Thumbnail data is nil")
                    return
                }

                let imageData = Data(thumbnailData)

                if let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self?.imageView.image = image
                    }
                } else {
                    print("Failed to create UIImage from data")
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
            // Chỉ cho phép kéo xuống
            if touchPoint.y >= 0 {
                // Update vị trí của imageView
                imageViewTopConstraint?.constant = touchPoint.y
                
                // Thay đổi opacity của background dựa trên khoảng cách kéo
                let progress = min(1.0, touchPoint.y / dismissThreshold)
                view.backgroundColor = UIColor.white.withAlphaComponent(1 - progress * 0.6)
            }
            
        case .ended:
            let velocity = gesture.velocity(in: view)
            
            // Nếu kéo xuống quá ngưỡng hoặc velocity đủ lớn
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
                // Animate quay về vị trí ban đầu
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
