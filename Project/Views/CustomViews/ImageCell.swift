import Foundation
import UIKit

/// A custom UICollectionViewCell subclass for displaying an image thumbnail with an optional dimming overlay.
final class ImageCell: UICollectionViewCell {
    
    // MARK: - UI Components
    private let thumbnailImageView = UIImageView()
    let dimView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.4)
        view.isHidden = true
        return view
    }()
    
    // MARK: - Initialization
    /// Initializes a new instance of `ImageCell`.
    ///
    /// This initializer sets up the views for the cell.
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    /// This initializer is not implemented, and attempting to use it will result in a fatal error.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup And Configure
/// This extension provides setup and configuration methods for the `ImageCell`.
extension ImageCell {
    
    // MARK: - Setup
    /// Sets up the UI components of the cell.
    /// This method configures the appearance and layout of the cell's subviews,
    /// including the thumbnail image view and the dim view.
    private func setupViews() {
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        contentView.addSubview(thumbnailImageView)
        thumbnailImageView.frame = contentView.bounds
        thumbnailImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        contentView.addSubview(dimView)
        dimView.frame = contentView.bounds
        dimView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    // MARK: - Configuration
    /// Configures the cell with an image represented by `AppMedia`.
    ///
    /// - Parameter appImage: An instance of `AppMedia` containing the image data.
    /// This method sets the image view's image based on the provided `AppMedia`
    /// instance, either from the thumbnail data or by loading from a local file.
    func configure(with appImage: AppMedia) {
        if let thumbnailData = appImage.thumbnail,
           let thumbnail = UIImage(data: thumbnailData) {
            thumbnailImageView.image = thumbnail
        } else {
            if let localIdentifier = appImage.localIdentifier,
               let image = UIImage(contentsOfFile: localIdentifier) {
                thumbnailImageView.image = image
            } else {
                thumbnailImageView.backgroundColor = .lightGray
            }
        }
    }
}

