//
//  ImageCell.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 14/10/2024.
//

import Foundation
import UIKit

class ImageCell: UICollectionViewCell {
    private let thumbnailImageView = UIImageView()
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        contentView.addSubview(thumbnailImageView)
        thumbnailImageView.frame = contentView.bounds
        thumbnailImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func configure(with appImage: AppImage) {
        titleLabel.text = appImage.title
        
        if let thumbnailData = appImage.thumbnail,
           let thumbnail = UIImage(data: thumbnailData) {
            thumbnailImageView.image = thumbnail
        } else {
            // If there's no thumbnail, you might want to load the full image
            // Keep in mind this could be inefficient for large images
            if let filepath = appImage.filepath,
               let image = UIImage(contentsOfFile: filepath) {
                thumbnailImageView.image = image
            } else {
                thumbnailImageView.backgroundColor = .lightGray
            }
        }
    }
}
