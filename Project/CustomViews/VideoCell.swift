//
//  VideoCell.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 14/10/2024.
//

import Foundation
import UIKit

class VideoCell: UICollectionViewCell {
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.backgroundColor = .systemIndigo
        button.layer.cornerRadius = 15
        return button
    }()
    
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
        backgroundColor = .clear
        
        // Add subviews
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(durationLabel)
        contentView.addSubview(playButton)
        contentView.addSubview(dimView)
        
        // Configure auto layout
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        playButton.translatesAutoresizingMaskIntoConstraints = false
        dimView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Thumbnail
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 64),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 64),
            
            // Title
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: playButton.leadingAnchor, constant: -8),
            
            // Duration
            durationLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 12),
            durationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            // Play button
            playButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            playButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 30),
            playButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Dim view
            dimView.topAnchor.constraint(equalTo: contentView.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with video: AppVideo) {
        if let thumbnail = video.thumbnail {
            thumbnailImageView.image = UIImage(data: thumbnail)
        }
        titleLabel.text = video.title
        
        // Format duration
        let duration = Int(video.duration)
        let minutes = duration / 60
        let seconds = duration % 60
        durationLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
}
