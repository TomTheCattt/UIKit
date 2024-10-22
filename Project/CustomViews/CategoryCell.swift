//
//  Cell.swift
//  UIKitProject
//
//  Created by Việt Anh Nguyễn on 03/10/2024.
//

import UIKit
import CoreData

// MARK: - CategoryCell
final class CategoryCell: UITableViewCell {
    // MARK: - Static Properties
    static let reuseIdentifier = String(describing: CategoryCell.self)
    
    // MARK: - UI Components
    let albumIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit  // Maintain aspect ratio
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = .gray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        [albumIconView, titleLabel, countLabel, arrowImageView].forEach {
            contentView.addSubview($0)
        }
        setupContraints()
    }
    
    private func setupContraints() {
        contentView.addSubview(albumIconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(countLabel)
        contentView.addSubview(arrowImageView)
        
        // Auto Layout Constraints
        NSLayoutConstraint.activate([
            // Album icon constraints
            albumIconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            albumIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            albumIconView.widthAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 1),  // Dynamic resizing
            albumIconView.heightAnchor.constraint(equalTo: albumIconView.widthAnchor),  // Keep aspect ratio
            
            // Title label constraints
            titleLabel.leadingAnchor.constraint(equalTo: albumIconView.trailingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            
            // Count label constraints
            countLabel.leadingAnchor.constraint(equalTo: albumIconView.trailingAnchor, constant: 16),
            countLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            countLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            // Arrow Image Constraints
            arrowImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            arrowImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 10),
            arrowImageView.heightAnchor.constraint(equalToConstant: 15)
        ])
    }
    
    // MARK: - Configuration
    func configure(with category: CategoryType) {
        let itemCount: Int
        let iconName: String
        let title: String
        
        switch category {
        case .image:
            itemCount = CoreDataManager.shared.fetchAppImagesCount()
            iconName = "photo"
            title = "Images"
            if itemCount > 0 {
                let images = CoreDataManager.shared.fetchLatestAppImages(limit: 4)
                albumIconView.image = createLayeredThumbnail(from: images.compactMap { UIImage(data: $0.thumbnail ?? Data()) })
            } else {
                albumIconView.image = UIImage(systemName: iconName)
            }
            
        case .video:
            itemCount = CoreDataManager.shared.fetchAppVideosCount()
            iconName = "video"
            title = "Videos"
            if itemCount > 0 {
                let videos = CoreDataManager.shared.fetchLatestAppVideos(limit: 4)
                albumIconView.image = createLayeredThumbnail(from: videos.compactMap { UIImage(data: $0.thumbnail ?? Data()) })
            } else {
                albumIconView.image = UIImage(systemName: iconName)
            }
        }
        
        titleLabel.text = title
        countLabel.text = "\(itemCount) items"
    }
    
    // MARK: - Helper Methods
    private func createLayeredThumbnail(from images: [UIImage]) -> UIImage {
        let size = CGSize(width: 80, height: 80)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        let numberOfImages = min(images.count, 4)
        let tileSize = CGSize(width: size.width / 2, height: size.height / 2)
        
        for (index, image) in images.prefix(numberOfImages).enumerated() {
            let origin = CGPoint(
                x: CGFloat(index % 2) * tileSize.width,
                y: CGFloat(index / 2) * tileSize.height
            )
            image.draw(in: CGRect(origin: origin, size: tileSize))
        }
        
        let layeredImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return layeredImage ?? UIImage()
    }
}

// MARK: - CoreDataManager Extension
extension CoreDataManager {
    func fetchLatestAppImages(limit: Int) -> [AppImage] {
        let fetchRequest: NSFetchRequest<AppImage> = AppImage.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        fetchRequest.fetchLimit = limit
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch latest AppImages: \(error)")
            return []
        }
    }
    
    func fetchLatestAppVideos(limit: Int) -> [AppVideo] {
        let fetchRequest: NSFetchRequest<AppVideo> = AppVideo.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        fetchRequest.fetchLimit = limit
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch latest AppVideos: \(error)")
            return []
        }
    }
}
