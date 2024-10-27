import UIKit
import CoreData
import Photos

class ListViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: ListViewControllerDelegate?
    var selectedCategory: CategoryType?
    private var dataManager: ListViewDataManager!
    private var dataSource: [NSManagedObject] = []
    private var collectionView: UICollectionView!
    private var noDataLabel: UILabel!
    private var isSelectionModeEnabled = false
    private var selectedItems: Set<IndexPath> = []
    private var bottomBarBottomConstraint: NSLayoutConstraint?
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private lazy var selectAllButton: UIBarButtonItem = {
        UIBarButtonItem(title: "Select All", style: .plain, target: self, action: #selector(selectAllTapped))
    }()
    
    private lazy var cancelButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(cancelSelectionTapped))
        button.tintColor = .systemRed
        return button
    }()
    
    private lazy var selectButton: UIBarButtonItem = {
        UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(toggleSelectionMode))
    }()
    
    private lazy var bottomBar: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemGray4
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.isEnabled = false
        button.addTarget(self, action: #selector(deleteSelectedItems), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDataManager()
        setupUI()
        loadData()
        setupNotifications()
        setupBottomBar()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Setup Extension
extension ListViewController {
    private func setupDataManager() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        dataManager = ListViewDataManager(
            context: appDelegate.persistentContainer.viewContext,
            mediaType: selectedCategory?.rawValue
        )
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        setupNavigationTitle()
        setupCollectionView()
        setupNavigationBar()
        setupNoDataLabel()
        setupLoadingIndicator()
    }
    
    private func setupNavigationTitle() {
        title = selectedCategory == .image ? "All Images" : "All Videos"
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        if selectedCategory == .image {
            layout.minimumInteritemSpacing = 0
            layout.minimumLineSpacing = 2
        } else {
            layout.minimumLineSpacing = 1
            layout.minimumInteritemSpacing = 0
        }
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .white
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let cellIdentifier = selectedCategory == .image ? "ImageCell" : "VideoCell"
        let cellClass = selectedCategory == .image ? ImageCell.self : VideoCell.self
        collectionView.register(cellClass, forCellWithReuseIdentifier: cellIdentifier)
        
        view.addSubview(collectionView)
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItems = [selectButton]
    }
    
    private func setupBottomBar() {
        view.addSubview(bottomBar)
        bottomBar.addSubview(deleteButton)
        
        let bottomConstraint = bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 100)
        bottomBarBottomConstraint = bottomConstraint
        
        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomConstraint,
            bottomBar.heightAnchor.constraint(equalToConstant: 80),
            
            deleteButton.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor),
            deleteButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalTo: bottomBar.widthAnchor, multiplier: 0.9),
            deleteButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupNoDataLabel() {
        noDataLabel = UILabel()
        noDataLabel.text = "No data available for this category."
        noDataLabel.textAlignment = .center
        noDataLabel.textColor = .gray
        noDataLabel.isHidden = true
        view.addSubview(noDataLabel)
        
        noDataLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noDataLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noDataLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
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
    private func loadData() {
        loadingIndicator.startAnimating()
        dataManager.fetchData { [weak self] result in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                self?.handleFetchResult(result)
            }
        }
    }
    
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
    
    @objc private func handleDataChange(_ notification: Notification) {
        if let updatedData = notification.userInfo?["updatedData"] as? [NSManagedObject] {
            updateUI(with: updatedData)
        }
    }
    
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
    private func updateUI() {
        let isEmpty = dataSource.isEmpty
        collectionView.isHidden = isEmpty
        noDataLabel.isHidden = !isEmpty
        
        if !isEmpty {
            collectionView.reloadData()
        }
    }
    
    private func updateUI(with data: [NSManagedObject]) {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
}

// MARK: - Selection Mode Extension
extension ListViewController {
    
    @objc private func toggleSelectionMode() {
        isSelectionModeEnabled.toggle()
        
        UIView.animate(withDuration: 0.3) {
            self.updateUIForSelectionMode()
            self.view.layoutIfNeeded()
        }
        
        collectionView.visibleCells.forEach { cell in
            if let imageCell = cell as? ImageCell {
                imageCell.setSelectionMode(self.isSelectionModeEnabled, isSelected: false)
            } else if let videoCell = cell as? VideoCell {
                videoCell.setSelectionMode(self.isSelectionModeEnabled, isSelected: false)
            }
        }
    }
    
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
    
    @objc private func selectAllTapped() {
        view.isUserInteractionEnabled = false
        
        let shouldSelectAll = selectedItems.count != dataSource.count
        
        if shouldSelectAll {
            selectedItems = Set((0..<dataSource.count).map { IndexPath(item: $0, section: 0) })
        } else {
            selectedItems.removeAll()
        }
        
        UIView.animate(withDuration: 0.2, animations: {
            self.collectionView.visibleCells.forEach { cell in
                if let imageCell = cell as? ImageCell {
                    imageCell.setSelectionMode(true, isSelected: shouldSelectAll)
                } else if let videoCell = cell as? VideoCell {
                    videoCell.setSelectionMode(true, isSelected: shouldSelectAll)
                }
            }
            
            self.updateDeleteButtonState()
            self.view.layoutIfNeeded()
        }) { _ in
            self.view.isUserInteractionEnabled = true
        }
    }
    
    @objc private func cancelSelectionTapped() {
        view.isUserInteractionEnabled = false
        
        isSelectionModeEnabled = false
        selectedItems.removeAll()
        
        UIView.animate(withDuration: 0.2, animations: {
            self.navigationItem.leftBarButtonItems = nil
            self.navigationItem.rightBarButtonItems = [self.selectButton]
            
            self.bottomBarBottomConstraint?.constant = 100
            
            self.collectionView.visibleCells.forEach { cell in
                if let imageCell = cell as? ImageCell {
                    imageCell.setSelectionMode(false, isSelected: false)
                } else if let videoCell = cell as? VideoCell {
                    videoCell.setSelectionMode(false, isSelected: false)
                }
            }
            
            self.view.layoutIfNeeded()
        }) { _ in
            self.view.isUserInteractionEnabled = true
        }
        
        updateDeleteButtonState()
    }
}

// MARK: - Bottom Bar Extension
extension ListViewController {
    private func showBottomBar() {
        view.layoutIfNeeded()
        bottomBarBottomConstraint?.constant = 0
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func hideBottomBar() {
        view.layoutIfNeeded()
        bottomBarBottomConstraint?.constant = 100
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func updateDeleteButtonState() {
        let selectedCount = selectedItems.count
        let itemType = selectedCategory == .image ? "image" : "video"
        let buttonTitle = "Delete \(selectedCount) \(itemType)\(selectedCount > 1 ? "s" : "")"
        
        deleteButton.setTitle(buttonTitle, for: .normal)
        deleteButton.backgroundColor = selectedCount > 0 ? .systemRed : .systemGray4
        deleteButton.isEnabled = selectedCount > 0
    }
}

// MARK: - UICollectionViewDataSource
extension ListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = dataSource[indexPath.item]
        
        if let item = item as? AppMedia {
            switch item.mediaType {
            case "video" :
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as! VideoCell
                cell.configure(with: item)
                cell.setSelectionMode(isSelectionModeEnabled, isSelected: selectedItems.contains(indexPath))
                return cell
            case "image" :
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
                cell.configure(with: item)
                cell.setSelectionMode(isSelectionModeEnabled, isSelected: selectedItems.contains(indexPath))
                return cell
            case .none:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as! VideoCell
                cell.configure(with: item)
                cell.setSelectionMode(isSelectionModeEnabled, isSelected: selectedItems.contains(indexPath))
                return cell
            case .some(_):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as! VideoCell
                cell.configure(with: item)
                cell.setSelectionMode(isSelectionModeEnabled, isSelected: selectedItems.contains(indexPath))
                return cell
            }
        }
        
        fatalError("Unknown cell type")
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if isSelectionModeEnabled {
            if selectedItems.contains(indexPath) {
                selectedItems.remove(indexPath)
            } else {
                selectedItems.insert(indexPath)
            }
            
            // Only reload the selected cell
            if let cell = collectionView.cellForItem(at: indexPath) {
                if let imageCell = cell as? ImageCell {
                    imageCell.setSelectionMode(true, isSelected: selectedItems.contains(indexPath))
                } else if let videoCell = cell as? VideoCell {
                    videoCell.setSelectionMode(true, isSelected: selectedItems.contains(indexPath))
                }
            }
            
            updateDeleteButtonState()
        } else {
            // Original detail view presentation code
            let item = dataSource[indexPath.item]
            let detailVC: UIViewController
            if let item = item as? AppMedia {
                switch item.mediaType {
                case "video" :
                    detailVC = VideoDetailViewController(video: item)
                case "image" :
                    detailVC = ImageDetailViewController(image: item)
                case .none:
                    detailVC = VideoDetailViewController(video: item)
                case .some(_):
                    detailVC = VideoDetailViewController(video: item)
                }
                let navController = UINavigationController(rootViewController: detailVC)
                navController.modalPresentationStyle = .fullScreen
                present(navController, animated: true)
            }
        }
    }
}

// MARK: - Media Handling
extension ListViewController {
    @objc private func deleteSelectedItems() {
        let message = "Are you sure you want to delete \(selectedItems.count) selected items?"
        let alert = UIAlertController(title: "Confirm Delete", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.performDeletion()
        })
        
        present(alert, animated: true)
    }
    
    private func performDeletion() {
        let itemsToDelete = selectedItems.map { dataSource[$0.item] }
        
        dataManager.deleteItems(itemsToDelete) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.showDeleteSuccessMessage()
                    self?.cancelSelectionTapped()
                    self?.loadData()
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
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
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ListViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if selectedCategory == .image {
            return CGSize(width: (view.frame.width / 2) - 1, height: 200)
        } else {
            let width = collectionView.bounds.width - 32
            return CGSize(width: width, height: 72)
        }
    }
}
    
    
