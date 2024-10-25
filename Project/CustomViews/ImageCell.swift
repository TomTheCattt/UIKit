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
    let dimView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.4)
        view.isHidden = true
        return view
    }()
    
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
        
        // Setup dim view
        contentView.addSubview(dimView)
        dimView.frame = contentView.bounds
        dimView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func configure(with appImage: AppImage) {
        if let thumbnailData = appImage.thumbnail,
           let thumbnail = UIImage(data: thumbnailData) {
            thumbnailImageView.image = thumbnail
        } else {
            if let filepath = appImage.filepath,
               let image = UIImage(contentsOfFile: filepath) {
                thumbnailImageView.image = image
            } else {
                thumbnailImageView.backgroundColor = .lightGray
            }
        }
    }
}

