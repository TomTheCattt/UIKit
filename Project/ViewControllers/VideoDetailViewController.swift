//
//  VideoDetailViewController.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 23/10/2024.
//
//
import UIKit
import AVKit
import Photos

class VideoDetailViewController: UIViewController {
    
    // MARK: - Properties
    
    private var player: AVPlayer?
    private var playerViewController: AVPlayerViewController?
    private var video: AppMedia
    
    // MARK: - Initialization
    
    init(video: AppMedia) {
        self.video = video
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        player?.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
    }
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPlayer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
    }
}

// MARK: - Setup
extension VideoDetailViewController {
    
    private func setupUI() {
        view.backgroundColor = .black
        title = video.title
    }
    
    private func setupPlayer() {
        guard let localIdentifier = video.localIdentifier else {
            print("Error: Video local identifier is nil")
            return
        }
        
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = fetchResult.firstObject else {
            print("Error: Could not find PHAsset with identifier: \(localIdentifier)")
            return
        }
        
        let options = PHVideoRequestOptions()
        options.version = .current
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { [weak self] (avAsset, _, info) in
            DispatchQueue.main.async {
                guard let self = self, let avAsset = avAsset else { return }
                
                let playerItem = AVPlayerItem(asset: avAsset)
                playerItem.addObserver(self,
                                    forKeyPath: #keyPath(AVPlayerItem.status),
                                    options: [.old, .new],
                                    context: nil)
                
                self.player = AVPlayer(playerItem: playerItem)
                self.playerViewController = AVPlayerViewController()
                self.playerViewController?.player = self.player
                
                guard let playerVC = self.playerViewController else {
                    print("Error: Failed to initialize AVPlayerViewController")
                    return
                }
                
                self.addChild(playerVC)
                self.view.addSubview(playerVC.view)
                playerVC.view.translatesAutoresizingMaskIntoConstraints = false
                
                NSLayoutConstraint.activate([
                    playerVC.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                    playerVC.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                    playerVC.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                    playerVC.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
                ])
                
                playerVC.didMove(toParent: self)
                
                try? AVAudioSession.sharedInstance().setCategory(.playback)
                try? AVAudioSession.sharedInstance().setActive(true)
            }
        }
    }
}
