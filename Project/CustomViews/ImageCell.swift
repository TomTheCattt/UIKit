//
//  ImageCell.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 14/10/2024.
//

import Foundation
import UIKit

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
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup And Configure
extension ImageCell {
    // MARK: - Setup
    private func setupViews() {
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        contentView.addSubview(thumbnailImageView)
        thumbnailImageView.frame = contentView.bounds
        thumbnailImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Setup dim view
        contentView.addSubview(dimView)
        dimView.frame = contentView.bounds
        dimView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    // MARK: - Configuration
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

