import UIKit
import CoreData
import Photos



// MARK: - MediaCell
final class MediaCell: UITableViewCell {
    // MARK: - Static Properties
    static let reuseIdentifier = String(describing: MediaCell.self)
    
    // MARK: - Properties
    private lazy var dataManager: DataManager = {
        return DataManager(context: CoreDataManager.shared.context, mediaType: nil)
    }()
    
    // MARK: - UI Components
    private let albumIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = DefaultValue.Fonts.bodyFont.bold()
        label.textColor = DefaultValue.Colors.accentColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = DefaultValue.Colors.footnoteColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = .systemGray2
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = DefaultValue.Colors.secondaryColor
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// MARK: - Setup And Configure
extension MediaCell {
    // MARK: - UI Setup
    private func setupUI() {
        [albumIconView, titleLabel, countLabel, arrowImageView].forEach {
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            // Album icon constraints
            albumIconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            albumIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            albumIconView.widthAnchor.constraint(equalToConstant: 80),
            albumIconView.heightAnchor.constraint(equalToConstant: 80),
            
            // Title label constraints
            titleLabel.leadingAnchor.constraint(equalTo: albumIconView.trailingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: arrowImageView.leadingAnchor, constant: -8),
            
            // Count label constraints
            countLabel.leadingAnchor.constraint(equalTo: albumIconView.trailingAnchor, constant: 16),
            countLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            countLabel.trailingAnchor.constraint(lessThanOrEqualTo: arrowImageView.leadingAnchor, constant: -8),
            
            // Arrow image constraints
            arrowImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            arrowImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 12),
            arrowImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    // MARK: - Configuration
    func configure(with category: CategoryType) {
        titleLabel.text = category.title
        
        // Initialize data manager with specific media type
        dataManager = DataManager(context: CoreDataManager.shared.context, mediaType: category.mediaType)
        
        // Fetch data to get count and thumbnails
        dataManager.fetchData { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let items):
                    let itemCount = items.count
                    self.countLabel.text = "\(itemCount) items"
                    
                    if itemCount > 0 {
                        // Get up to 4 items for the thumbnail grid
                        let thumbnailItems = Array(items.prefix(4))
                        let thumbnailImages = thumbnailItems.compactMap { item -> UIImage? in
                            guard let mediaItem = item as? AppMedia,
                                  let thumbnailData = mediaItem.thumbnail else {
                                return nil
                            }
                            return UIImage(data: thumbnailData)
                        }
                        
                        self.albumIconView.image = self.createLayeredThumbnail(from: thumbnailImages)
                    } else {
                        // Show placeholder for empty state
                        self.albumIconView.image = UIImage(systemName: category.systemIconName)?
                            .withRenderingMode(.alwaysTemplate)
                        self.albumIconView.tintColor = .systemGray2
                    }
                    
                case .failure(let error):
                    print("Error fetching data: \(error)")
                    // Show placeholder on error
                    self.albumIconView.image = UIImage(systemName: category.systemIconName)?
                        .withRenderingMode(.alwaysTemplate)
                    self.albumIconView.tintColor = .systemGray2
                    self.countLabel.text = "0 items"
                }
            }
        }
    }
}

// MARK: - Helper Methods
extension MediaCell {
    private func createLayeredThumbnail(from images: [UIImage]) -> UIImage {
        let size = CGSize(width: 80, height: 80)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.systemGray6.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        
        let numberOfImages = min(images.count, 4)
        let padding: CGFloat = 2
        let tileSize = CGSize(
            width: (size.width - (padding * 3)) / 2,
            height: (size.height - (padding * 3)) / 2
        )
        
        for (index, image) in images.prefix(numberOfImages).enumerated() {
            let origin = CGPoint(
                x: padding + CGFloat(index % 2) * (tileSize.width + padding),
                y: padding + CGFloat(index / 2) * (tileSize.height + padding)
            )
            
            // Create a rounded rect path for each image
            let imageRect = CGRect(origin: origin, size: tileSize)
            let path = UIBezierPath(roundedRect: imageRect, cornerRadius: 4)
            context?.addPath(path.cgPath)
            context?.clip()
            
            // Draw the image
            image.draw(in: imageRect)
            
            // Reset the clipping path for the next image
            context?.resetClip()
        }
        
        let layeredImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return layeredImage ?? UIImage()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        albumIconView.image = nil
        titleLabel.text = nil
        countLabel.text = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Ensure smooth corners on the album icon
        albumIconView.layer.cornerRadius = 8
        albumIconView.layer.masksToBounds = true
    }
}
