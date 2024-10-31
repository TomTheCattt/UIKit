import Foundation
import UIKit
import Photos

// MARK: - ImageDetailView
/// A custom view for displaying image.
class ImageDetailView: UIView {
    // MARK: - Private Properties
    
    /// The media item being displayed
    private let image: AppMedia
    
    /// The initial touch point for pan gesture tracking
    private var initialTouchPoint: CGPoint = .zero
    
    /// The vertical distance required to trigger dismissal
    private let dismissThreshold: CGFloat = 100
    
    /// Constraint for managing the image view's vertical position
    private var imageViewTopConstraint: NSLayoutConstraint?
    
    /// Delegate to handle view dismissal
    weak var delegate: ImageDetailViewDelegate?
    
    // MARK: - UI Components
    
    /// The main image view for displaying the image
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        return view
    }()
    
    /// Button to close the image detail view
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = DefaultValue.Colors.accentColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    
    /// Initializes the image detail view with a specific media item
    /// - Parameter image: The media item to display
    init(image: AppMedia) {
        self.image = image
        super.init(frame: .zero)
        setupUI()
        loadImage()
        backgroundColor = DefaultValue.Colors.secondaryColor
    }
    
    /// Required initializer for interface builder (not implemented)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


// MARK: - UI Setup
/// Setup how this view will display.
extension ImageDetailView {
    
    /// Configures the user interface components and their constraints
    private func setupUI() {
        addSubview(imageView)
        addSubview(closeButton)
        
        // Create top constraint for image view to enable pan dismissal
        imageViewTopConstraint = imageView.topAnchor.constraint(equalTo: topAnchor)
        
        // Set up layout constraints
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
        
        // Add interactive gestures
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        
        imageView.addGestureRecognizer(pinchGesture)
        imageView.addGestureRecognizer(panGesture)
        
        // Configure close button action
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }
    
    /// Loads the image from Photos framework using the local identifier
    private func loadImage() {
        guard let localIdentifier = image.localIdentifier else {
            print("Error: Media local identifier is nil")
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

        imageManager.requestImage(for: asset,
                                  targetSize: targetSize,
                                  contentMode: .aspectFill,
                                  options: options) { [weak self] (result, info) in
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
/// Actions that this view will execute.
extension ImageDetailView {
    /// Handles closing the image detail view
    @objc private func closeTapped() {
        delegate?.imageDetailViewDidRequestDismiss(self)
    }
}


// MARK: - Gesture Handling
/// Handling user gesture to interact with the image.
extension ImageDetailView {
    /// Handles pinch-to-zoom gesture
    /// - Parameter gesture: The pinch gesture recognizer
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard gesture.state == .began || gesture.state == .changed else { return }
        
        imageView.transform = imageView.transform.scaledBy(
            x: gesture.scale,
            y: gesture.scale
        )
        gesture.scale = 1.0
    }
    
    /// Handles pan gesture for dismissing the view
    /// - Parameter gesture: The pan gesture recognizer
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
