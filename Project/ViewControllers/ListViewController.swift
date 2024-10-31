
import UIKit
import CoreData
import Photos

/// `ListViewController` handles the display and management of media items,
/// such as images and videos, with functionality for selection, deletion, and
/// toggling between selection and presentation modes.
class ListViewController: UIViewController {
    
    // MARK: - Properties
    
    /// Delegate to notify other components of events in this view controller,
    /// such as updates to the item count or selected category.
    weak var delegate: ListViewControllerDelegate?
    
    /// The currently selected category (e.g., image or video) that determines
    /// the type of items displayed in the list.
    var selectedCategory: CategoryType?
    
    /// Manages data operations such as fetching and updating media items.
    private var dataManager: DataManager!
    
    /// The data source holding media items retrieved from the database.
    private var dataSource: [NSManagedObject] = []
    
    /// Flag indicating whether selection mode is enabled, which allows
    /// users to select and perform actions on multiple items.
    private var isSelectionModeEnabled = false
    
    /// Holds the index paths of currently selected items, allowing for
    /// easy reference and batch operations like deletion.
    private var selectedItems: Set<IndexPath> = []
    
    /// Controller responsible for presenting media items in fullscreen or
    /// other interactive modes.
    private var mediaPresentationController: MediaPresentationController?
    
    // MARK: - UI Elements
    
    /// The main view displaying the list of media items, cast to `ListView` type.
    private var listView: ListView {
        return view as! ListView
    }
    
    /// Button to select all items in the list when in selection mode.
    private lazy var selectAllButton: UIBarButtonItem = {
        UIBarButtonItem(title: "Select All", style: .plain, target: self, action: #selector(selectAllTapped))
    }()
    
    /// Button to cancel selection mode, reverting UI to its normal state.
    private lazy var cancelButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(cancelSelectionTapped))
        button.tintColor = .systemRed
        return button
    }()
    
    /// Button to toggle selection mode, allowing users to enter or exit
    /// a state where multiple items can be selected.
    private lazy var selectButton: UIBarButtonItem = {
        UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(toggleSelectionMode))
    }()
    
    // MARK: - Lifecycle
    
    /// Loads the main view, initializing it as a `ListView` instance.
    override func loadView() {
        view = ListView(frame: UIScreen.main.bounds)
    }
    
    /// Called after the view has been loaded. Sets up the media presentation
    /// controller and performs initial view configuration.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Initializes the media presentation controller with the current
        /// `ListViewController` instance as the parent.
        mediaPresentationController = MediaPresentationController(parentViewController: self)
        
        /// Calls the `setupViewController` method to configure the initial
        /// view setup, such as data fetching, UI configuration, and navigation.
        setupViewController()
    }
    
    /// Removes the view controller from the notification center to prevent
    /// memory leaks when the instance is deallocated.
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}


// MARK: - Setup Extension
extension ListViewController {
    
    // MARK: - Setup

    /// Configures the main components of `ListViewController`, including the data manager,
    /// collection view, navigation bar, delete button, data loading, and notifications.
    private func setupViewController() {
        setupDataManager()
        setupCollectionView()
        setupNavigationBar()
        setupDeleteButton()
        loadData()
        setupNotifications()
    }
    
    /// Initializes the `ListViewDataManager` with the Core Data context and the media type for
    /// the selected category. The data manager is responsible for fetching and managing data.
    private func setupDataManager() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        dataManager = DataManager(
            context: appDelegate.persistentContainer.viewContext,
            mediaType: selectedCategory?.rawValue
        )
    }
    
    /// Configures the collection view's delegate, data source, cell registration, and layout.
    /// Registers either `ImageCell` or `VideoCell` based on the selected category, and updates
    /// the collection view layout to match the category type.
    private func setupCollectionView() {
        listView.collectionView.delegate = self
        listView.collectionView.dataSource = self
        
        let cellIdentifier = selectedCategory == .image ? "ImageCell" : "VideoCell"
        let cellClass = selectedCategory == .image ? ImageCell.self : VideoCell.self
        listView.collectionView.register(cellClass, forCellWithReuseIdentifier: cellIdentifier)
        
        listView.updateCollectionViewLayout(for: selectedCategory ?? .image)
    }
    
    /// Sets up the navigation bar title and right bar button based on the selected media category.
    /// The title displays either the image or video title from `DefaultValue.String`.
    private func setupNavigationBar() {
        title = selectedCategory == .image ? DefaultValue.String.imageViewTitle.uppercased() : DefaultValue.String.videoViewTitle.uppercased()
        navigationItem.rightBarButtonItems = [selectButton]
    }
    
    /// Adds a target to the delete button, enabling it to trigger the `deleteSelectedItems` action
    /// when tapped. This button allows users to delete selected media items.
    private func setupDeleteButton() {
        listView.deleteButton.addTarget(self, action: #selector(deleteSelectedItems), for: .touchUpInside)
    }
    
    /// Registers for notifications regarding data changes, specifically observing "DataDidChange"
    /// to update the collection view when the data is modified elsewhere in the app.
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataChange(_:)),
            name: NSNotification.Name("DataDidChange"),
            object: nil
        )
    }
}


// MARK: - Data Management Extension
extension ListViewController {

    /// Initiates data loading by starting the loading indicator, then fetches data asynchronously
    /// through the `dataManager`. Upon completion, the result is processed on the main thread.
    private func loadData() {
        listView.loadingIndicator.startAnimating()
        dataManager.fetchData { [weak self] result in
            DispatchQueue.main.async {
                self?.listView.loadingIndicator.stopAnimating()
                self?.handleFetchResult(result)
            }
        }
    }
    
    /// Processes the result from `fetchData`. On success, it updates `dataSource` with fetched data,
    /// refreshes the UI, and notifies the delegate. On failure, it presents an alert displaying the error.
    ///
    /// - Parameter result: The result of the data fetch, which can either be a success with an array
    ///   of `NSManagedObject`s or a failure with an error.
    private func handleFetchResult(_ result: Result<[NSManagedObject], Error>) {
        switch result {
        case .success(let fetchedData):
            dataSource = fetchedData
            updateUI()
            notifyDelegate()
        case .failure(let error):
            showAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
    /// Handles data updates via notifications. If updated data is provided in the notification's
    /// userInfo, it refreshes the UI with this data to ensure consistency across views.
    ///
    /// - Parameter notification: A notification containing updated data, usually sent when data is modified
    ///   elsewhere in the app.
    @objc private func handleDataChange(_ notification: Notification) {
        if let updatedData = notification.userInfo?["updatedData"] as? [NSManagedObject] {
            updateUI(with: updatedData)
        }
    }
    
    /// Notifies the delegate of an update in item count, passing the current `dataSource` count
    /// and the selected category. Used for communicating data changes to other controllers.
    private func notifyDelegate() {
        delegate?.listViewController(
            self,
            didUpdateItemCount: dataSource.count,
            forCategory: selectedCategory ?? .image
        )
    }
}


// MARK: - UI Update Extension
extension ListViewController {

    /// Updates the UI based on the current state of `dataSource`. If `dataSource` is empty,
    /// it hides the collection view and displays a "no data" label. Otherwise, it shows the
    /// collection view and reloads its data to reflect the current items.
    private func updateUI() {
        let isEmpty = dataSource.isEmpty
        listView.collectionView.isHidden = isEmpty
        listView.noDataLabel.isHidden = !isEmpty
        
        if !isEmpty {
            listView.collectionView.reloadData()
        }
    }
    
    /// Refreshes the UI to reflect any changes in the provided data. The collection view
    /// is reloaded asynchronously on the main thread, ensuring that the UI updates without
    /// blocking other tasks.
    ///
    /// - Parameter data: An array of `NSManagedObject` representing the updated data to be
    ///   displayed in the collection view.
    private func updateUI(with data: [NSManagedObject]) {
        DispatchQueue.main.async {
            self.listView.collectionView.reloadData()
        }
    }
}


// MARK: - Selection Mode Extension
extension ListViewController {

    /// Toggles the selection mode for the list view, enabling or disabling it as needed.
    /// In selection mode, UI elements update to allow users to select multiple items.
    /// Animates the UI change and updates cells to reflect selection state.
    @objc private func toggleSelectionMode() {
        isSelectionModeEnabled.toggle()
        
        UIView.animate(withDuration: 0.3) { [self] in
            self.updateUIForSelectionMode()
            listView.layoutIfNeeded()
        }
        
        listView.collectionView.visibleCells.forEach { cell in
            if let imageCell = cell as? ImageCell {
                imageCell.setSelectionMode(self.isSelectionModeEnabled, isSelected: false)
            } else if let videoCell = cell as? VideoCell {
                videoCell.setSelectionMode(self.isSelectionModeEnabled, isSelected: false)
            }
        }
    }
    
    /// Configures the UI to display selection-related elements when selection mode is enabled.
    /// Adjusts the navigation bar buttons and shows or hides the bottom bar based on selection mode.
    private func updateUIForSelectionMode() {
        if isSelectionModeEnabled {
            navigationItem.rightBarButtonItems = []
            navigationItem.leftBarButtonItems = [cancelButton]
            navigationItem.rightBarButtonItems = [selectAllButton]
            showBottomBar()
        } else {
            navigationItem.leftBarButtonItems = nil
            navigationItem.rightBarButtonItems = [selectButton]
            hideBottomBar()
            selectedItems.removeAll()
        }
        updateDeleteButtonState()
    }
    
    /// Selects or deselects all items in the collection view based on the current selection state.
    /// Updates the cell selection mode and adjusts the delete button state accordingly.
    @objc private func selectAllTapped() {
        view.isUserInteractionEnabled = false
        
        let shouldSelectAll = selectedItems.count != dataSource.count
        
        if shouldSelectAll {
            selectedItems = Set((0..<dataSource.count).map { IndexPath(item: $0, section: 0) })
        } else {
            selectedItems.removeAll()
        }
        
        UIView.animate(withDuration: 0.2, animations: { [self] in
            self.listView.collectionView.visibleCells.forEach { cell in
                if let imageCell = cell as? ImageCell {
                    imageCell.setSelectionMode(true, isSelected: shouldSelectAll)
                } else if let videoCell = cell as? VideoCell {
                    videoCell.setSelectionMode(true, isSelected: shouldSelectAll)
                }
            }
            
            self.updateDeleteButtonState()
            listView.layoutIfNeeded()
        }) { _ in
            self.view.isUserInteractionEnabled = true
        }
    }
    
    /// Exits selection mode and clears any selected items. Updates the UI to hide selection-related
    /// elements and reset cells to their default state.
    @objc private func cancelSelectionTapped() {
        view.isUserInteractionEnabled = false
        
        isSelectionModeEnabled = false
        selectedItems.removeAll()
        
        UIView.animate(withDuration: 0.2, animations: { [self] in
            self.navigationItem.leftBarButtonItems = nil
            self.navigationItem.rightBarButtonItems = [self.selectButton]
            
            listView.bottomBarBottomConstraint?.constant = 100
            
            listView.collectionView.visibleCells.forEach { cell in
                if let imageCell = cell as? ImageCell {
                    imageCell.setSelectionMode(false, isSelected: false)
                } else if let videoCell = cell as? VideoCell {
                    videoCell.setSelectionMode(false, isSelected: false)
                }
            }
            
            listView.layoutIfNeeded()
        }) { _ in
            self.view.isUserInteractionEnabled = true
        }
        
        updateDeleteButtonState()
    }
}


// MARK: - Bottom Bar Extension
extension ListViewController {

    /// Displays the bottom bar by animating its position from off-screen to its designated position.
    /// This is typically shown in selection mode to allow actions on selected items.
    private func showBottomBar() {
        listView.layoutIfNeeded()
        listView.bottomBarBottomConstraint?.constant = 0
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.listView.layoutIfNeeded()
        }
    }
    
    /// Hides the bottom bar by moving it off-screen. This is used when exiting selection mode.
    private func hideBottomBar() {
        listView.layoutIfNeeded()
        listView.bottomBarBottomConstraint?.constant = 100
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            self.listView.layoutIfNeeded()
        }
    }
    
    /// Updates the state of the delete button based on the number of selected items.
    /// The button's title displays the count of items selected, and it is enabled or disabled
    /// depending on whether any items are selected.
    private func updateDeleteButtonState() {
        let selectedCount = selectedItems.count
        let itemType = selectedCategory == .image ? "image" : "video"
        let buttonTitle = "Delete \(selectedCount) \(itemType)\(selectedCount > 1 ? "s" : "")"
        
        listView.deleteButton.setTitle(buttonTitle, for: .normal)
        listView.deleteButton.backgroundColor = selectedCount > 0 ? .systemRed : .systemGray4
        listView.deleteButton.isEnabled = selectedCount > 0
    }
}


// MARK: - UICollectionViewDataSource
extension ListViewController: UICollectionViewDataSource {
    
    /// Returns the number of items in the collection view section.
    /// - Parameters:
    ///   - collectionView: The collection view requesting this information.
    ///   - section: The number of the section.
    /// - Returns: The number of items in `dataSource`.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    /// Configures and returns the cell for a given index path based on the media type.
    /// The cell is set up for either image or video content and adapts to selection mode.
    /// - Parameters:
    ///   - collectionView: The collection view requesting the cell.
    ///   - indexPath: The index path specifying the cell's location.
    /// - Returns: A configured `UICollectionViewCell` for the specified index path.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = dataSource[indexPath.item]
        
        if let item = item as? AppMedia {
            switch item.mediaType {
            case "video":
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as! VideoCell
                cell.configure(with: item)
                cell.setSelectionMode(isSelectionModeEnabled, isSelected: selectedItems.contains(indexPath))
                return cell
            case "image":
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
                cell.configure(with: item)
                cell.setSelectionMode(isSelectionModeEnabled, isSelected: selectedItems.contains(indexPath))
                return cell
            default:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as! VideoCell
                cell.configure(with: item)
                cell.setSelectionMode(isSelectionModeEnabled, isSelected: selectedItems.contains(indexPath))
                return cell
            }
        }
        
        fatalError("Unknown cell type")
    }
    
    /// Handles the selection of a cell, toggling its selected state if selection mode is active.
    /// If selection mode is not active, it presents a detail view for the selected media.
    /// - Parameters:
    ///   - collectionView: The collection view informing the delegate about the selection.
    ///   - indexPath: The index path of the selected item.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isSelectionModeEnabled {
            if selectedItems.contains(indexPath) {
                selectedItems.remove(indexPath)
            } else {
                selectedItems.insert(indexPath)
            }
            
            // Reloads only the selected cell to update its selection appearance.
            if let cell = collectionView.cellForItem(at: indexPath) {
                if let imageCell = cell as? ImageCell {
                    imageCell.setSelectionMode(true, isSelected: selectedItems.contains(indexPath))
                } else if let videoCell = cell as? VideoCell {
                    videoCell.setSelectionMode(true, isSelected: selectedItems.contains(indexPath))
                }
            }
            
            updateDeleteButtonState()
        } else {
            let item = dataSource[indexPath.item]
            if let item = item as? AppMedia {
                if item.mediaType == "image" {
                    // Presents the image detail view for the selected item.
                    let imageDetailView = ImageDetailView(image: item)
                    imageDetailView.delegate = self
                    mediaPresentationController?.present(mediaView: imageDetailView)
                } else if item.mediaType == "video" {
                    // Presents the video player view for the selected item.
                    let videoPlayerView = VideoPlayerView(video: item)
                    videoPlayerView.onDismiss = { [weak self] in
                        self?.mediaPresentationController?.dismiss()
                    }
                    mediaPresentationController?.present(mediaView: videoPlayerView)
                }
            }
        }
    }
}


// MARK: - Media Handling
extension ListViewController {
    
    /// Initiates the deletion of selected items by presenting a confirmation alert.
    /// The alert confirms whether the user wants to proceed with deleting the selected items.
    @objc private func deleteSelectedItems() {
        let message = "Are you sure you want to delete \(selectedItems.count) selected items?"
        let alert = UIAlertController(title: "Confirm Delete", message: message, preferredStyle: .alert)
        
        // Add actions for canceling or confirming deletion
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.performDeletion()
        })
        
        present(alert, animated: true)
    }
    
    /// Executes the deletion of selected items by passing them to the data manager.
    /// After successful deletion, the UI is updated, and a success message is displayed.
    private func performDeletion() {
        let itemsToDelete = selectedItems.map { dataSource[$0.item] }
        
        dataManager.deleteItems(itemsToDelete) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.showDeleteSuccessMessage()
                    self?.cancelSelectionTapped()
                    self?.loadData() // Reload data to refresh the UI
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    /// Displays a success alert after deletion, showing the count and type of deleted items.
    private func showDeleteSuccessMessage() {
        let itemType = selectedCategory == .image ? "image" : "video"
        let message = "\(selectedItems.count) \(itemType)\(selectedItems.count > 1 ? "s" : "") deleted successfully"
        
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}


// MARK: - Permission Handling
extension ListViewController {
    
    /// Requests access to the user's photo library if the permission status is undetermined.
    /// - Parameter completion: A closure that is called with a Boolean indicating if access is granted.
    ///
    /// If the photo library access status is `.notDetermined`, this method requests authorization
    /// and then calls the completion handler with `true` if access is granted, otherwise `false`.
    /// If the status is already determined, the completion handler is called immediately.
    private func requestPhotoLibraryAccess(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { newStatus in
                completion(newStatus == .authorized)
            }
        } else {
            completion(status == .authorized)
        }
    }
    
    /// Displays an alert with a specified title and message.
    /// - Parameters:
    ///   - title: The title text for the alert.
    ///   - message: The message content for the alert.
    ///
    /// This function creates an alert controller with an OK button to dismiss it,
    /// presenting the user with information or error messages as specified.
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}


// MARK: - UICollectionViewDelegateFlowLayout
extension ListViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    /// Calculates the size for the item at the specified index path based on the selected category.
    /// - Parameters:
    ///   - collectionView: The collection view requesting the size.
    ///   - collectionViewLayout: The layout object that is responsible for the layout of the collection view.
    ///   - indexPath: The index path of the item whose size is being requested.
    /// - Returns: A CGSize representing the width and height of the item.
    ///
    /// For images, this method returns a width that is half the width of the view minus one, and a fixed height of 200.
    /// For videos, it returns a width equal to the collection view's width minus 32 and a fixed height of 72.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if selectedCategory == .image {
            return CGSize(width: (view.frame.width / 2) - 1, height: 200)
        } else {
            let width = collectionView.bounds.width - 32
            return CGSize(width: width, height: 72)
        }
    }
    
    /// Specifies the insets for the section at the specified index.
    /// - Parameters:
    ///   - collectionView: The collection view requesting the insets.
    ///   - collectionViewLayout: The layout object that is responsible for the layout of the collection view.
    ///   - section: The index of the section whose insets are being requested.
    /// - Returns: A UIEdgeInsets structure that defines the margins for the section.
    ///
    /// For the video category, this method returns an inset of 20 points from the top, with no insets on the left, bottom, or right.
    /// For other categories, it returns zero insets.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if selectedCategory == .video {
            return UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        }
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}


// MARK: - ImageDetailViewDelegate Extension
extension ListViewController: ImageDetailViewDelegate {
    
    /// Called when the user requests to dismiss the `ImageDetailView`.
    /// - Parameter view: The `ImageDetailView` instance that initiated the dismissal request.
    ///
    /// This method informs the `MediaPresentationController` to dismiss the current media view, allowing for a seamless return
    /// to the previous screen in the app.
    func imageDetailViewDidRequestDismiss(_ view: ImageDetailView) {
        mediaPresentationController?.dismiss()
    }
}



