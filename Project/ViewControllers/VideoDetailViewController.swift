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
    // MARK: - Properties
    private var player: AVPlayer?
    private var playerViewController: AVPlayerViewController?
    private var video: AppVideo
    
    // MARK: - Initialization
    init(video: AppVideo) {
        self.video = video
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPlayer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .black
        title = video.title
        
//        let closeButton = UIBarButtonItem(
//            image: UIImage(systemName: "xmark"),
//            style: .plain,
//            target: self,
//            action: #selector(closeTapped)
//        )
//        navigationItem.rightBarButtonItem = closeButton
    }
    
    private func setupPlayer() {
        // Kiểm tra filepath và đảm bảo URL có thể được khởi tạo
        guard let filepath = video.filepath,
              !filepath.isEmpty,  // Đảm bảo filepath không rỗng
              let url = URL(string: filepath) else {
            print("Invalid video file path")
            return
        }
        
        // Khởi tạo AVPlayer với URL
        player = AVPlayer(url: url)
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        
        // Đảm bảo playerViewController đã được khởi tạo thành công
        if let playerVC = playerViewController {
            // Thêm PlayerViewController làm child view controller
            addChild(playerVC)
            view.addSubview(playerVC.view)
            
            // Tắt thuộc tính auto-resizing mask để sử dụng Auto Layout
            playerVC.view.translatesAutoresizingMaskIntoConstraints = false
            
            // Thiết lập các ràng buộc cho view của playerVC để chiếm toàn bộ màn hình
            NSLayoutConstraint.activate([
                playerVC.view.topAnchor.constraint(equalTo: view.topAnchor),
                playerVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                playerVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                playerVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            
            // Thông báo hoàn thành việc thêm child view controller
            playerVC.didMove(toParent: self)
            
            // Bắt đầu phát video
            player?.play()
        } else {
            print("Failed to initialize AVPlayerViewController")
        }
    }

    
    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
