//
//  VideoDetailViewController.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 23/10/2024.
//

import UIKit
import AVKit
import Photos

// MARK: - VideoDetailViewController
class VideoPlayerView: UIView {
    
    // MARK: - Properties
    private var player: AVPlayer?
    private var video: AppMedia
    private var timeObserverToken: Any?
    private var isControlsVisible = true
    private var controlsTimer: Timer?
    private var playerItem: AVPlayerItem?
    private var itemObserver: NSKeyValueObservation?
    private var locked = false
    
    // MARK: - UI Components
    private lazy var playerLayer: AVPlayerLayer = {
        let layer = AVPlayerLayer()
        layer.videoGravity = .resizeAspect
        return layer
    }()
    
    private lazy var controlsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var customTopRightButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var videoSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.tintColor = .white
        return slider
    }()
    
    private lazy var controlsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var leftButtonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 20
        return stackView
    }()
    
    private lazy var centerButtonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 20
        return stackView
    }()
    
    private lazy var currentTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var totalTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var lockButton: UIButton = createButton(systemName: locked ? "lock.fill" : "lock.open.fill")
    private lazy var rightButton: UIButton = createButton(systemName: "button.programmable")
    
    private lazy var previousButton: UIButton = createButton(systemName: "backward.end.fill")
    private lazy var backwardButton: UIButton = createButton(systemName: "backward.10")
    private lazy var playPauseButton: UIButton = createButton(systemName: "play.fill")
    private lazy var forwardButton: UIButton = createButton(systemName: "forward.10")
    private lazy var nextButton: UIButton = createButton(systemName: "forward.end.fill")
    
    // MARK: - Callbacks
    var onDismiss: (() -> Void)?
    
    // MARK: - Initialization
    init(video: AppMedia) {
        self.video = video
        super.init(frame: .zero)
        setupUI()
        setupPlayer()
        setupGestureRecognizers()
        setupNotifications()
        backgroundColor = .black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removePeriodicTimeObserver()
        removeItemObserver()
        removeNotifications()
        controlsTimer?.invalidate()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

// MARK: - UI Setup
extension VideoPlayerView {
    private func setupUI() {
            layer.addSublayer(playerLayer)
            addSubview(controlsContainerView)
            setupControlsContainer()
            setupControls()
        }
    
    private func setupControlsContainer() {
            NSLayoutConstraint.activate([
                controlsContainerView.topAnchor.constraint(equalTo: topAnchor),
                controlsContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
                controlsContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
                controlsContainerView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
    
    private func setupControls() {
        controlsContainerView.addSubview(backButton)
        controlsContainerView.addSubview(customTopRightButton)
        controlsContainerView.addSubview(videoSlider)
        controlsContainerView.addSubview(currentTimeLabel)
        controlsContainerView.addSubview(totalTimeLabel)
        controlsContainerView.addSubview(controlsStackView)
        
        setupButtonGroups()
        setupControlsConstraints()
        setupActions()
    }
    
    private func setupButtonGroups() {
        leftButtonsStackView.addArrangedSubview(lockButton)
        
        centerButtonsStackView.addArrangedSubview(previousButton)
        centerButtonsStackView.addArrangedSubview(backwardButton)
        centerButtonsStackView.addArrangedSubview(playPauseButton)
        centerButtonsStackView.addArrangedSubview(forwardButton)
        centerButtonsStackView.addArrangedSubview(nextButton)
        
        controlsStackView.addArrangedSubview(leftButtonsStackView)
        controlsStackView.addArrangedSubview(centerButtonsStackView)
        controlsStackView.addArrangedSubview(rightButton)
    }
    
    private func setupControlsConstraints() {
            NSLayoutConstraint.activate([
                backButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
                backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                backButton.widthAnchor.constraint(equalToConstant: 44),
                backButton.heightAnchor.constraint(equalToConstant: 44),
                
                customTopRightButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
                customTopRightButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                customTopRightButton.widthAnchor.constraint(equalToConstant: 44),
                customTopRightButton.heightAnchor.constraint(equalToConstant: 44),
                
                currentTimeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                currentTimeLabel.bottomAnchor.constraint(equalTo: controlsStackView.topAnchor, constant: -8),
                
                videoSlider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 16),
                videoSlider.centerYAnchor.constraint(equalTo: currentTimeLabel.centerYAnchor),
                videoSlider.trailingAnchor.constraint(equalTo: totalTimeLabel.leadingAnchor, constant: -16),
                
                totalTimeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                totalTimeLabel.bottomAnchor.constraint(equalTo: controlsStackView.topAnchor, constant: -8),
                
                controlsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                controlsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                controlsStackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
                controlsStackView.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        playPauseButton.addTarget(self, action: #selector(playPauseButtonTapped), for: .touchUpInside)
        backwardButton.addTarget(self, action: #selector(backwardButtonTapped), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(forwardButtonTapped), for: .touchUpInside)
        videoSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        lockButton.addTarget(self, action: #selector(lockButtonTapped), for: .touchUpInside)
    }
}

// MARK: - Player Setup
extension VideoPlayerView {
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
                
                self.playerItem = AVPlayerItem(asset: avAsset)
                self.player = AVPlayer(playerItem: self.playerItem)
                self.playerLayer.player = self.player
                
                self.setupItemObserver()
                self.setupPeriodicTimeObserver()
                self.showControls()
                self.setupAudioSession()
            }
        }
    }
    
    private func setupItemObserver() {
        itemObserver = playerItem?.observe(\.status, options: [.new]) { [weak self] (item, _) in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    self?.player?.play()
                    self?.playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                    self?.updateTimeLabels()
                case .failed:
                    print("Failed to load video: \(String(describing: item.error))")
                case .unknown:
                    print("Unknown player item status")
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func removeItemObserver() {
        itemObserver?.invalidate()
        itemObserver = nil
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    private func removeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Time Observation
extension VideoPlayerView {
    private func setupPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.updateVideoSlider()
            self?.updateTimeLabels()
        }
    }
    
    private func removePeriodicTimeObserver() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
    
    private func updateVideoSlider() {
        guard let duration = player?.currentItem?.duration.seconds,
              !duration.isNaN,
              let currentTime = player?.currentTime().seconds else {
            return
        }
        
        videoSlider.value = Float(currentTime / duration)
    }
    
    private func updateTimeLabels() {
        guard let duration = player?.currentItem?.duration.seconds,
              !duration.isNaN,
              let currentTime = player?.currentTime().seconds else {
            return
        }
        
        let currentTimeString = formatTimeString(currentTime)
        let durationString = formatTimeString(duration)
        
        currentTimeLabel.text = currentTimeString
        totalTimeLabel.text = durationString
    }
    
    private func formatTimeString(_ time: Double) -> String {
        let hours = Int(time / 3600)
        let minutes = Int(time / 60) % 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Controls Management
extension VideoPlayerView {
    private func resetPlayback() {
        player?.seek(to: .zero)
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        showControls()
    }
    
    private func showControls() {
        controlsTimer?.invalidate()
        
        UIView.animate(withDuration: 0.3) {
            self.controlsContainerView.alpha = 1
        }
        
        isControlsVisible = true
        
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.hideControls()
        }
    }
    
    private func hideControls() {
        UIView.animate(withDuration: 0.3) {
            self.controlsContainerView.alpha = 0
        }
        isControlsVisible = false
    }
}

// MARK: - Helper Methods
extension VideoPlayerView {
    private func createButton(systemName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = .white
        return button
    }
    
    private func lockScreen() {
        if locked {
            var supportedInterfaceOrientations: UIInterfaceOrientation {
                return .portrait
            }
        }
    }
}

// MARK: - Notification Handlers
extension VideoPlayerView {
    @objc private func playerDidFinishPlaying() {
        DispatchQueue.main.async { [weak self] in
            self?.resetPlayback()
        }
    }

    @objc private func handleEnterBackground() {
        player?.pause()
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
    }
}

// MARK: - Actions
extension VideoPlayerView {
    
    @objc private func handleTap() {
        if isControlsVisible {
            hideControls()
        } else {
            showControls()
        }
    }
    
    @objc private func backButtonTapped() {
        player?.pause()
        onDismiss?()
    }
    
    @objc private func playPauseButtonTapped() {
        if player?.rate == 0 {
            if let currentTime = player?.currentTime(),
               let duration = player?.currentItem?.duration,
               currentTime >= duration {
                player?.seek(to: .zero)
            }
            player?.play()
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        } else {
            player?.pause()
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        }
        showControls()
    }
    
    @objc private func backwardButtonTapped() {
        guard let currentTime = player?.currentTime() else { return }
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: -10, preferredTimescale: 1))
        player?.seek(to: newTime)
        showControls()
    }
    
    @objc private func forwardButtonTapped() {
        guard let currentTime = player?.currentTime() else { return }
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: 10, preferredTimescale: 1))
        player?.seek(to: newTime)
        showControls()
    }
    
    @objc private func sliderValueChanged() {
        guard let duration = player?.currentItem?.duration else { return }
        let time = CMTime(seconds: Double(videoSlider.value) * duration.seconds, preferredTimescale: 1)
        player?.seek(to: time)
        showControls()
    }
    
    @objc private func lockButtonTapped() {
        locked.toggle()
    }
}
