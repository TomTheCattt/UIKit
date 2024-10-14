//
//  VideoCell.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 14/10/2024.
//

import Foundation
import UIKit


class VideoCell: UICollectionViewCell {
    private let thumbnailImageView = UIImageView()
    private let titleLabel = UILabel()
    private let durationLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Setup thumbnail image view
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        contentView.addSubview(thumbnailImageView)
        thumbnailImageView.frame = contentView.bounds
        thumbnailImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Setup title label
        titleLabel.textAlignment = .left
        titleLabel.textColor = .white
        titleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup duration label
        durationLabel.textAlignment = .right
        durationLabel.textColor = .white
        durationLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        contentView.addSubview(durationLabel)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 40),
            
            durationLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            durationLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -8),
            durationLabel.widthAnchor.constraint(equalToConstant: 60),
            durationLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    func configure(with appVideo: AppVideo) {
        titleLabel.text = appVideo.title
        
        if let thumbnailData = appVideo.thumbnail,
           let thumbnail = UIImage(data: thumbnailData) {
            thumbnailImageView.image = thumbnail
        } else {
            thumbnailImageView.backgroundColor = .lightGray
        }
        
        durationLabel.text = formatDuration(appVideo.duration)
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}
