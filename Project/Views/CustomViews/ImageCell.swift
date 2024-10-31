import Foundation
import UIKit

/// A custom UICollectionViewCell subclass for displaying an image thumbnail with an optional dimming overlay.
class ImageCell: UICollectionViewCell {
    
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
extension ImageCell {
    // MARK: - Setup
    /// Sets up the UI components of the cell.
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
