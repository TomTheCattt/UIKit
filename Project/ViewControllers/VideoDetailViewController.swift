//
//  VideoDetailViewController.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 23/10/2024.
//
import UIKit
import AVKit

// MARK: - VideoDetailViewController.swift

class VideoDetailViewController: UIViewController {
    private var player: AVPlayer?
    private var playerViewController: AVPlayerViewController?
    private var video: AppVideo
    
    init(video: AppVideo) {
        self.video = video
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPlayer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        title = video.title
    }
    
    private func setupPlayer() {
        guard let filepath = video.filepath, !filepath.isEmpty else {
            print("Error: Video filepath is empty or nil")
            return
        }
        
        if !FileManager.default.fileExists(atPath: filepath) {
                print("Error: File does not exist at path: \(filepath)")
                return
            } else {
                print("File exists at path: \(filepath)")
            }
        
        let videoURL: URL
        
        // Check if it's a local or remote URL
        if filepath.hasPrefix("http://") || filepath.hasPrefix("https://") {
            // Remote URL
            guard let url = URL(string: filepath) else {
                print("Error: Invalid remote URL")
                return
            }
            videoURL = url
        } else {
            // Local file path
            videoURL = URL(fileURLWithPath: filepath)
        }
        
        // Create asset and check if it's playable
        let asset = AVAsset(url: videoURL)
        let playerItem = AVPlayerItem(asset: asset)
        
        // Add observer for player item status
        playerItem.addObserver(self,
                             forKeyPath: #keyPath(AVPlayerItem.status),
                             options: [.old, .new],
                             context: nil)
        
        // Initialize player with the item
        player = AVPlayer(playerItem: playerItem)
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        
        guard let playerVC = playerViewController else {
            print("Error: Failed to initialize AVPlayerViewController")
            return
        }
        
        // Add player view controller
        addChild(playerVC)
        view.addSubview(playerVC.view)
        playerVC.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            playerVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            playerVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        playerVC.didMove(toParent: self)
        
        // Enable background audio (if needed)
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    // Observer method for player item status
    override func observeValue(forKeyPath keyPath: String?,
                             of object: Any?,
                             change: [NSKeyValueChangeKey : Any]?,
                             context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            // Check status
            switch status {
            case .readyToPlay:
                print("Player is ready to play")
                player?.play()
            case .failed:
                if let error = player?.currentItem?.error {
                    print("Player failed with error: \(error.localizedDescription)")
                }
            case .unknown:
                print("Player status is unknown")
            @unknown default:
                break
            }
        }
    }
    
    // Clean up observer when view controller is deallocated
    deinit {
        player?.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
    }
}
