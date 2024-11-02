import Foundation
import UIKit

// MARK: - MediaPresentationController
/// A controller responsible for presenting media views modally with a customizable overlay and layout adjustments for device orientation changes.
final class MediaPresentationController {
    private weak var parentViewController: UIViewController?
    private var containerView: UIView?
    private var overlayView: UIView?
    private var mediaView: UIView?
    private var mediaViewConstraints: [NSLayoutConstraint] = []

    /// Initializes a new instance of `MediaPresentationController`.
    /// - Parameter parentViewController: The view controller that will present the media view.
    init(parentViewController: UIViewController) {
        self.parentViewController = parentViewController
        setupOrientationNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Sets up notifications for device orientation changes.
    private func setupOrientationNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOrientationChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    /// Handles orientation change notifications to update the layout of the media view.
    @objc private func handleOrientationChange() {
        updateLayout(for: UIDevice.current.orientation)
    }
    
    /// Updates the layout of the media view based on the current device orientation.
    /// - Parameter orientation: The current orientation of the device.
    private func updateLayout(for orientation: UIDeviceOrientation) {
        guard let containerView = containerView,
              let mediaView = mediaView else { return }

        DispatchQueue.main.async {
            // Deactivate any existing constraints
            NSLayoutConstraint.deactivate(self.mediaViewConstraints)
            self.mediaViewConstraints.removeAll()
            
            // Set mediaView to be full screen within containerView
            self.mediaViewConstraints = [
                mediaView.topAnchor.constraint(equalTo: containerView.topAnchor),
                mediaView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                mediaView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                mediaView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ]
            
            UIView.animate(withDuration: 0.3) {
                NSLayoutConstraint.activate(self.mediaViewConstraints)
                containerView.layoutIfNeeded()
            }
        }
    }

    /// Presents the specified media view modally.
    /// - Parameter mediaView: The media view to present.
    func present(mediaView: UIView) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else { return }
        
        self.mediaView = mediaView
        
        // Create and setup overlay view
        let overlay = UIView()
        overlay.backgroundColor = .black
        overlay.alpha = 0
        overlay.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(overlay)
        self.overlayView = overlay
        
        // Create and setup container view
        let container = UIView()
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(container)
        self.containerView = container
        
        // Pin overlay and container to the window’s bounds
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: window.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: window.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: window.bottomAnchor),
            
            container.topAnchor.constraint(equalTo: window.topAnchor),
            container.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: window.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: window.bottomAnchor)
        ])
        
        // Add mediaView to container and make it full screen
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(mediaView)
        mediaView.alpha = 0

        // Set mediaView to fill the containerView
        mediaViewConstraints = [
            mediaView.topAnchor.constraint(equalTo: container.topAnchor),
            mediaView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            mediaView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ]
        NSLayoutConstraint.activate(mediaViewConstraints)
        
        // Animate the presentation
        UIView.animate(withDuration: 0.3) {
            overlay.alpha = 0.5
            mediaView.alpha = 1
        }
        
        // Set window level to ensure the overlay is above other UI elements
        window.windowLevel = .statusBar + 1
    }

    /// Dismisses the presented media view.
    /// - Parameter completion: A closure to execute after the dismissal is complete.
    func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.overlayView?.alpha = 0
            self.containerView?.alpha = 0
        }, completion: { _ in
            // Reset window level
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                window.windowLevel = .normal
            }
            
            NSLayoutConstraint.deactivate(self.mediaViewConstraints)
            self.mediaViewConstraints.removeAll()
            
            self.overlayView?.removeFromSuperview()
            self.containerView?.removeFromSuperview()
            self.mediaView = nil
            completion?()
        })
    }
}
