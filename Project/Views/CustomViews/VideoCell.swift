import Foundation
import UIKit

/// A custom UICollectionViewCell subclass for displaying video thumbnails, titles, and durations.
final class VideoCell: UICollectionViewCell {
    
    // MARK: - UI Components
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = DefaultValue.Colors.accentColor
        label.font = DefaultValue.Fonts.bodyFont.bold()
        return label
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.textColor = DefaultValue.Colors.footnoteColor
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = DefaultValue.Colors.sideMenuBackgroundColor
        return view
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.backgroundColor = .systemIndigo
        return button
    }()
    
    let dimView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.4)
        view.isHidden = true
        return view
    }()
    
    // MARK: - Initialization
    /// Initializes a new instance of `VideoCell`.
    ///
    /// This initializer sets the cell's background color and sets up its views.
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = DefaultValue.Colors.primaryColor
        setupViews()
    }
    
    /// This initializer is not implemented, and attempting to use it will result in a fatal error.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


// MARK: - Setup And Configure
/// This extension provides setup and configuration methods for the `VideoCell`.
extension VideoCell {
    
    // MARK: - Setup

    /// Sets up the UI components of the cell.
    /// This method initializes the background color and adds subviews to the content view,
    /// configuring their layout constraints for proper display.
    private func setupViews() {
        backgroundColor = .clear
        
        contentView.addSubview(containerView)
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(playButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(durationLabel)
        contentView.addSubview(dimView)
        
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        playButton.translatesAutoresizingMaskIntoConstraints = false
        dimView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 80),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 80),
            
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 20),
            
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 90),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 35),
            titleLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.5),
            
            durationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 90),
            durationLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 60),
            
            playButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            playButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            playButton.widthAnchor.constraint(equalToConstant: 20),
            playButton.heightAnchor.constraint(equalToConstant: 20),
            
            dimView.topAnchor.constraint(equalTo: contentView.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    // MARK: - Configuration
    /// Configures the cell with video information from an `AppMedia` instance.
    ///
    /// - Parameter video: An instance of `AppMedia` containing the video data.
    /// This method sets the thumbnail image, title, and duration labels based on the provided video information.
    func configure(with video: AppMedia) {
        if let thumbnail = video.thumbnail {
            thumbnailImageView.image = UIImage(data: thumbnail)
        }
        titleLabel.text = video.title
        
        let duration = Int(video.duration)
        let minutes = duration / 60
        let seconds = duration % 60
        durationLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
}


