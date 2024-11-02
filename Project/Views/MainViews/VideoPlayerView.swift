import UIKit
import AVKit
import Photos

// MARK: - VideoDetailViewController
/// A custom view for displaying and controlling video playback.
final class VideoPlayerView: UIView {
    
    // MARK: - Properties
    /// The video player responsible for playback.
    private var player: AVPlayer?
    
    /// The video data to be displayed.
    private var video: AppMedia
    
    /// A token for observing time updates in the player.
    private var timeObserverToken: Any?
    
    /// Boolean indicating if playback controls are visible.
    private var isControlsVisible = true
    
    /// Timer for hiding playback controls after a duration.
    private var controlsTimer: Timer?
    
    /// The current player item representing the video.
    private var playerItem: AVPlayerItem?
    
    /// Key-value observer for monitoring changes in `playerItem`.
    private var itemObserver: NSKeyValueObservation?
    
    /// Indicates whether the player is in locked mode.
    private var locked = false
    
    /// Boolean to check if the video view is flipped.
    private var isFlipped = false
    
    // MARK: - UI Components
    /// Layer that displays the video content.
    private lazy var playerLayer: AVPlayerLayer = {
        let layer = AVPlayerLayer()
        layer.videoGravity = .resizeAspect
        return layer
    }()
    
    /// Container for all video playback controls.
    private lazy var controlsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// Button to return to the previous screen.
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    /// Button to capture a screenshot or snapshot of the current video frame.
    private lazy var captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "camera.viewfinder"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    /// Slider for tracking and adjusting video progress.
    private lazy var videoSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.tintColor = .white
        return slider
    }()
    
    /// Stack view holding main control buttons.
    private lazy var controlsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    /// Stack view for left-aligned control buttons.
    private lazy var leftButtonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 20
        return stackView
    }()
    
    /// Stack view for center-aligned control buttons.
    private lazy var centerButtonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 20
        return stackView
    }()
    
    /// Label displaying the current playback time.
    private lazy var currentTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// Label displaying the total duration of the video.
    private lazy var totalTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// Button to lock or unlock the controls.
    private lazy var lockButton: UIButton = createButton(systemName: locked ? "lock.fill" : "lock.open.fill")
    
    /// Button to flip the video orientation.
    private lazy var flipButton: UIButton = createButton(systemName: "rectangle.landscape.rotate")
    
    /// Button to go to the previous video.
    private lazy var previousButton: UIButton = createButton(systemName: "backward.end.fill")
    
    /// Button to rewind the video by 10 seconds.
    private lazy var backwardButton: UIButton = createButton(systemName: "backward.10")
    
    /// Button to play or pause the video.
    private lazy var playPauseButton: UIButton = createButton(systemName: "play.fill")
    
    /// Button to fast-forward the video by 10 seconds.
    private lazy var forwardButton: UIButton = createButton(systemName: "forward.10")
    
    /// Button to go to the next video.
    private lazy var nextButton: UIButton = createButton(systemName: "forward.end.fill")
    
    /// Property to track audio session state.
    private var isAudioSessionActive = false
    
    // MARK: - Callbacks
    /// Callback triggered when dismissing the video player.
    var onDismiss: (() -> Void)?
    
    // MARK: - Initialization
    /// Initializes the video player view with a given video.
    /// - Parameter video: The `AppMedia` object representing the video content.
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
        cleanupAudioSession()
        player?.replaceCurrentItem(with: nil)
        player = nil
    }
    
    // MARK: - Layout
    /// Updates the layout of the subviews when the view's bounds change.
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}


// MARK: - UI Setup
/// Setup view interface and each element constraints, declare functions for buttons.
extension VideoPlayerView {
    
    /// Sets up the UI elements of the video player, including the player layer and controls container.
    private func setupUI() {
        layer.addSublayer(playerLayer)
        addSubview(controlsContainerView)
        setupControlsContainer()
        setupControls()
    }
    
    /// Configures the layout constraints for the controls container view to ensure it covers the entire video player view.
    private func setupControlsContainer() {
        NSLayoutConstraint.activate([
            controlsContainerView.topAnchor.constraint(equalTo: topAnchor),
            controlsContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            controlsContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            controlsContainerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    /// Adds control components to the controls container and sets up button groups and constraints.
    private func setupControls() {
        controlsContainerView.addSubview(backButton)
        controlsContainerView.addSubview(captureButton)
        controlsContainerView.addSubview(videoSlider)
        controlsContainerView.addSubview(currentTimeLabel)
        controlsContainerView.addSubview(totalTimeLabel)
        controlsContainerView.addSubview(controlsStackView)
        
        setupButtonGroups()
        setupControlsConstraints()
        setupActions()
    }
    
    /// Organizes buttons into left and center groups for consistent layout within the controls container.
    private func setupButtonGroups() {
        leftButtonsStackView.addArrangedSubview(lockButton)
        
        centerButtonsStackView.addArrangedSubview(previousButton)
        centerButtonsStackView.addArrangedSubview(backwardButton)
        centerButtonsStackView.addArrangedSubview(playPauseButton)
        centerButtonsStackView.addArrangedSubview(forwardButton)
        centerButtonsStackView.addArrangedSubview(nextButton)
        
        controlsStackView.addArrangedSubview(leftButtonsStackView)
        controlsStackView.addArrangedSubview(centerButtonsStackView)
        controlsStackView.addArrangedSubview(flipButton)
    }
    
    /// Sets up Auto Layout constraints for each control component to arrange them within the player view.
    private func setupControlsConstraints() {
        NSLayoutConstraint.activate([
            // Back button constraints
            backButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Capture button constraints
            captureButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            captureButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            captureButton.widthAnchor.constraint(equalToConstant: 44),
            captureButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Time labels and video slider constraints
            currentTimeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            currentTimeLabel.bottomAnchor.constraint(equalTo: controlsStackView.topAnchor, constant: -8),
            
            videoSlider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 16),
            videoSlider.centerYAnchor.constraint(equalTo: currentTimeLabel.centerYAnchor),
            videoSlider.trailingAnchor.constraint(equalTo: totalTimeLabel.leadingAnchor, constant: -16),
            
            totalTimeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            totalTimeLabel.bottomAnchor.constraint(equalTo: controlsStackView.topAnchor, constant: -8),
            
            // Controls stack view constraints
            controlsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            controlsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            controlsStackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
            controlsStackView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    /// Assigns actions to control buttons, allowing user interaction with the video player (e.g., play/pause, seek, lock, etc.).
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        playPauseButton.addTarget(self, action: #selector(playPauseButtonTapped), for: .touchUpInside)
        backwardButton.addTarget(self, action: #selector(backwardButtonTapped), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(forwardButtonTapped), for: .touchUpInside)
        videoSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        lockButton.addTarget(self, action: #selector(lockButtonTapped), for: .touchUpInside)
        flipButton.addTarget(self, action: #selector(flipButtonTapped), for: .touchUpInside)
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
    }
}


// MARK: - Player Setup
/// Setup custom player view with designed controller.
extension VideoPlayerView {
    
    /// Configures the player with an `AVPlayerItem` for the video asset identified by the `localIdentifier`.
    /// If the video asset is not found, logs an error. Sets up time and status observers for the player.
    private func setupPlayer() {
        guard let localIdentifier = video.localIdentifier else {
            print("Error: Video local identifier is nil")
            return
        }
        
        cleanupExistingPlayer()
        
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
    
    private func cleanupExistingPlayer() {
        player?.pause()
        playerItem = nil
        player?.replaceCurrentItem(with: nil)
        player = nil
        removePeriodicTimeObserver()
        removeItemObserver()
        cleanupAudioSession()
    }
    
    /// Observes the status of the `AVPlayerItem` to handle different states such as ready to play, failed, or unknown.
    /// Automatically plays the video when ready and updates the UI accordingly.
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
    
    /// Removes the observer on the `AVPlayerItem` status to prevent memory leaks.
    private func removeItemObserver() {
        itemObserver?.invalidate()
        itemObserver = nil
    }
    
    /// Configures the audio session for playback, allowing audio to play even when the device is in silent mode.
    private func setupAudioSession() {
        guard !isAudioSessionActive else { return } // Prevent multiple activations
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Deactivate any existing session first
            if audioSession.isOtherAudioPlaying {
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            }
            
            // Configure and activate the session
            try audioSession.setCategory(.playback, mode: .moviePlayback, options: [])
            try audioSession.setActive(true)
            isAudioSessionActive = true
            
        } catch {
            print("Failed to setup audio session: \(error)")
            isAudioSessionActive = false
        }
    }
    
    private func cleanupAudioSession() {
        guard isAudioSessionActive else { return } // Only cleanup if active
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            isAudioSessionActive = false
        } catch {
            print("Failed to cleanup audio session: \(error)")
        }
    }
    
    /// Sets up gesture recognizers for the player view, allowing user interaction such as tap to show/hide controls.
    private func setupGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }
    
    /// Registers for system notifications, including when the player finishes playing and when the app enters the background.
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
    
    /// Removes registered notifications to prevent unwanted behavior and memory leaks.
    private func removeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}


// MARK: - Time Observation
/// Handle observe and update time label.
extension VideoPlayerView {
    
    /// Sets up a periodic time observer on the player that updates the video slider and time labels at regular intervals.
    /// The interval is set to 0.5 seconds for smooth updating of the UI.
    private func setupPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.updateVideoSlider()
            self?.updateTimeLabels()
        }
    }
    
    /// Removes the periodic time observer from the player to release resources and prevent memory leaks.
    private func removePeriodicTimeObserver() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
    
    /// Updates the video slider's current position based on the player's current time and total duration.
    private func updateVideoSlider() {
        guard let duration = player?.currentItem?.duration.seconds,
              !duration.isNaN,
              let currentTime = player?.currentTime().seconds else {
            return
        }
        
        videoSlider.value = Float(currentTime / duration)
    }
    
    /// Updates the current time label and total duration label for the video based on the player's current time and total duration.
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
    
    /// Formats a time value in seconds into a string of the format "HH:MM:SS" if hours are present, or "MM:SS" otherwise.
    /// - Parameter time: Time in seconds to be formatted.
    /// - Returns: A formatted time string.
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
/// Handling display and hide controls.
extension VideoPlayerView {
    
    /// Resets the video playback to the beginning, updates the play/pause button to show the play icon, and makes the controls visible.
    private func resetPlayback() {
        player?.seek(to: .zero)
        cleanupAudioSession()
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        showControls()
    }
    
    /// Shows the playback controls by animating their visibility to full opacity and starts a timer to hide the controls after a short duration.
    /// This function also resets any existing timer to ensure the controls remain visible for the specified duration.
    private func showControls() {
        controlsTimer?.invalidate()  // Cancel any existing timer
        
        UIView.animate(withDuration: 0.3) {
            self.controlsContainerView.alpha = 1
        }
        
        isControlsVisible = true
        
        // Automatically hide controls after 3 seconds
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.hideControls()
        }
    }
    
    /// Hides the playback controls by animating their visibility to zero opacity, setting the `isControlsVisible` flag to false.
    private func hideControls() {
        UIView.animate(withDuration: 0.3) {
            self.controlsContainerView.alpha = 0
        }
        isControlsVisible = false
    }
}


// MARK: - Helper Methods
/// Support functions for better user experience and generate view.
extension VideoPlayerView {
    
    /// Creates a reusable UIButton configured with a given system icon.
    /// - Parameter systemName: The name of the SF Symbol to use as the button's image.
    /// - Returns: A configured UIButton instance.
    private func createButton(systemName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = .white
        return button
    }
    
    /// Displays a success alert notifying the user that an image has been saved to the Photos library.
    private func showSuccessMessage() {
        let alert = UIAlertController(
            title: "Success",
            message: "Image saved to Photos",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if let viewController = self.window?.rootViewController {
            viewController.present(alert, animated: true)
        }
    }

    /// Displays an error alert notifying the user that an image save attempt failed.
    private func showErrorMessage() {
        let alert = UIAlertController(
            title: "Error",
            message: "Failed to save image",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if let viewController = self.window?.rootViewController {
            viewController.present(alert, animated: true)
        }
    }

    /// Displays an alert requesting the user to allow Photos access in Settings to enable image saving functionality.
    /// This alert provides an option to navigate to the app's Settings page.
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Permission Required",
            message: "Please allow access to Photos in Settings to save images",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        if let viewController = self.window?.rootViewController {
            viewController.present(alert, animated: true)
        }
    }
}


// MARK: - Notification Handlers
///notifications related to the video player's playback state and app lifecycle events.
extension VideoPlayerView {
    
    /// Handles the event when the video player finishes playing the video.
    /// Resets playback to the beginning and shows controls.
    @objc private func playerDidFinishPlaying() {
        DispatchQueue.main.async { [weak self] in
            self?.cleanupAudioSession()
            self?.resetPlayback()
        }
    }
    
    /// Handles the event when the app enters the background.
    /// Pauses the video playback and updates the play button to display the play icon.
    @objc private func handleEnterBackground() {
        cleanupAudioSession()
        player?.pause()
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
    }
}


// MARK: - Actions
/// Handling user interactions with this view.
extension VideoPlayerView {
    
    /// Handles tap gesture on the video player view. Toggles the visibility of playback controls based on their current state.
    @objc private func handleTap() {
        if isControlsVisible {
            hideControls()
        } else {
            showControls()
        }
    }
    
    /// Action for when the back button is tapped: Pauses the video and triggers the onDismiss closure to exit the player.
    @objc private func backButtonTapped() {
        player?.pause()
        cleanupAudioSession()
        onDismiss?()
    }
    
    /// Action for when the play/pause button is tapped: Toggles video playback and updates the play/pause button icon accordingly.
    @objc private func playPauseButtonTapped() {
        if player?.rate == 0 {
            if let currentTime = player?.currentTime(),
               let duration = player?.currentItem?.duration,
               currentTime >= duration {
                player?.seek(to: .zero)
            }
            setupAudioSession() // Ensure audio session is active before playing
            player?.play()
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        } else {
            player?.pause()
            cleanupAudioSession()
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        }
        showControls()
    }
    
    /// Action for when the backward button is tapped: Seeks the video playback 10 seconds back.
    @objc private func backwardButtonTapped() {
        guard let currentTime = player?.currentTime() else { return }
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: -10, preferredTimescale: 1))
        player?.seek(to: newTime)
        showControls()
    }
    
    /// Action for when the forward button is tapped: Seeks the video playback 10 seconds forward.
    @objc private func forwardButtonTapped() {
        guard let currentTime = player?.currentTime() else { return }
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: 10, preferredTimescale: 1))
        player?.seek(to: newTime)
        showControls()
    }
    
    /// Action for when the video slider value is changed: Seeks video playback to the corresponding time based on slider's position.
    @objc private func sliderValueChanged() {
        guard let duration = player?.currentItem?.duration else { return }
        let time = CMTime(seconds: Double(videoSlider.value) * duration.seconds, preferredTimescale: 1)
        player?.seek(to: time)
        showControls()
    }
    
    /// Action for when the lock button is tapped: Toggles screen orientation locking and updates the lock button's icon.
    @objc private func lockButtonTapped() {
        locked.toggle()
        let lockImage = UIImage(systemName: locked ? "lock.fill" : "lock.open.fill")
        lockButton.setImage(lockImage, for: .normal)
        let currentOrientation = UIDevice.current.orientation
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            if locked {
                // Locks to the current orientation
                switch currentOrientation {
                case .portrait:
                    appDelegate.orientationLock = .portrait
                case .landscapeLeft:
                    appDelegate.orientationLock = .landscapeRight
                case .landscapeRight:
                    appDelegate.orientationLock = .landscapeLeft
                case .portraitUpsideDown:
                    appDelegate.orientationLock = .portraitUpsideDown
                default:
                    break
                }
            } else {
                appDelegate.orientationLock = .all
            }
            
            // Forces device orientation update
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
    
    /// Action for when the flip button is tapped: Toggles flipping of the video player view horizontally.
    @objc private func flipButtonTapped() {
        isFlipped.toggle()
        let flipTransform = CATransform3DMakeRotation(isFlipped ? .pi : 0, 0, 1, 0)
        playerLayer.transform = flipTransform
    }
    
    /// Action for when the capture button is tapped: Captures the current video frame as an image and saves it to the Photos library and shows an alert on success, error, or if permission is needed.
    @objc private func captureButtonTapped() {
        guard let player = player else { return }
        
        let imageGenerator = AVAssetImageGenerator(asset: player.currentItem?.asset ?? AVAsset())
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: player.currentTime().seconds, preferredTimescale: 600)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let image = UIImage(cgImage: cgImage)
            
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else {
                    DispatchQueue.main.async {
                        self.showPermissionAlert()
                    }
                    return
                }
                
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            self.showSuccessMessage()
                        } else {
                            print("Error saving photo: \(String(describing: error))")
                            self.showErrorMessage()
                        }
                    }
                }
            }
        } catch {
            print("Error generating image: \(error)")
            showErrorMessage()
        }
    }
}


// MARK: - Video Player Handlers
extension VideoPlayerView: UIApplicationDelegate {
    func applicationDidEnterBackground(_ application: UIApplication) {
        player?.pause()
        cleanupAudioSession()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        cleanupExistingPlayer()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        cleanupAudioSession()
    }
}


