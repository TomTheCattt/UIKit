import UIKit
import CoreData
import Photos

class ListViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: ListViewControllerDelegate?
    var selectedCategory: CategoryType?
    
    private var dataManager: ListViewDataManager!
    private var dataSource: [NSManagedObject] = []
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private var collectionView: UICollectionView!
    private var noDataLabel: UILabel!
    private var updateFromAlbumButton: UIButton!
    private var updateFromLinkButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDataManager()
        setupUI()
        loadData()
    }
    
    // MARK: - Setup
    private func setupDataManager() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        dataManager = ListViewDataManager(
            context: appDelegate.persistentContainer.viewContext,
            category: selectedCategory
        )
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        setupNavigationTitle()
        setupCollectionView()
        setupNavigationBar()
        setupNoDataLabel()
        setupUpdateButtons()
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
            layout.minimumLineSpacing = 1
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
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
        navigationItem.rightBarButtonItem = addButton
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
    
    private func setupUpdateButtons() {
        updateFromAlbumButton = UIButton(type: .system)
        updateFromAlbumButton.setTitle("Update from Album", for: .normal)
        updateFromAlbumButton.addTarget(self, action: #selector(updateFromAlbumTapped), for: .touchUpInside)
        
        updateFromLinkButton = UIButton(type: .system)
        updateFromLinkButton.setTitle("Update from Link", for: .normal)
        updateFromLinkButton.addTarget(self, action: #selector(updateFromLinkTapped), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [updateFromAlbumButton, updateFromLinkButton])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: noDataLabel.bottomAnchor, constant: 20),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
        ])
    }
    
    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Data Loading
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
    
    // MARK: - UI Updates
    private func updateUI() {
        let isEmpty = dataSource.isEmpty
        collectionView.isHidden = isEmpty
        noDataLabel.isHidden = !isEmpty
        updateFromAlbumButton.isHidden = !isEmpty
        updateFromLinkButton.isHidden = !isEmpty
        
        if !isEmpty {
            collectionView.reloadData()
        }
    }
    
    private func notifyDelegate() {
        delegate?.listViewController(
            self,
            didUpdateItemCount: dataSource.count,
            forCategory: selectedCategory ?? .image
        )
    }
    
    // MARK: - Actions
    @objc private func updateFromAlbumTapped() {
        requestPhotoLibraryAccess { [weak self] granted in
            guard granted else {
                self?.showAlert(title: "Access Denied", message: "Please allow access to your photo library in Settings.")
                return
            }
            
            DispatchQueue.main.async {
                self?.fetchAssetsFromAlbum()
            }
        }
    }
    
    @objc private func updateFromLinkTapped() {
        let dialog = URLInputDialog(presentingViewController: self)
        dialog.delegate = self
        dialog.present()
    }
    
    @objc private func addButtonTapped() {
        let actionSheet = UIAlertController(title: "Add New", message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Add from Album", style: .default) { [weak self] _ in
            self?.updateFromAlbumTapped()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Add from Link", style: .default) { [weak self] _ in
            self?.updateFromLinkTapped()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(actionSheet, animated: true)
    }
    
    // MARK: - Media Handling
    private func fetchAssetsFromAlbum() {
        loadingIndicator.startAnimating()
        
        let fetchResult = PHAsset.fetchAssets(
            with: selectedCategory == .image ? .image : .video,
            options: PHFetchOptions()
        )
        
        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        dataManager.saveMediaFromAssets(assets) { [weak self] result in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                
                switch result {
                case .success(let updateInfo):
                    self?.showUpdateResultPopup(with: updateInfo)
                    self?.loadData()
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showUpdateResultPopup(with info: DataUpdateInfo) {
        let popupView = UIView()
        popupView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        popupView.layer.cornerRadius = 10
        popupView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = info.message
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        popupView.addSubview(label)
        view.addSubview(popupView)
        
        NSLayoutConstraint.activate([
            popupView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            popupView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            popupView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.9),
            
            label.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -16),
            label.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -16)
        ])
        
        // Animation hiển thị
        popupView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            popupView.alpha = 1
        }
        
        // Tự động ẩn sau 2 giây
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            UIView.animate(withDuration: 0.3, animations: {
                popupView.alpha = 0
            }) { _ in
                popupView.removeFromSuperview()
            }
        }
    }
    
    // MARK: - Helper Methods
    private func requestPhotoLibraryAccess(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - URLInputDialogDelegate
extension ListViewController: URLInputDialogDelegate {
    func urlInputDialog(_ dialog: URLInputDialog, didEnterURL urlString: String) {
        guard let url = URL(string: urlString) else {
            showAlert(title: "Invalid URL", message: "Please enter a valid URL.")
            return
        }
        
        loadingIndicator.startAnimating()
        dataManager.downloadAndSaveMedia(from: url) { [weak self] result in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                switch result {
                case .success(let message):
                    self?.showAlert(title: "Success", message: message)
                    self?.loadData()
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    func urlInputDialogDidCancel(_ dialog: URLInputDialog) {
        // Handle cancel if needed
    }
}

// MARK: - UICollectionViewDataSource
extension ListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = dataSource[indexPath.item]
        
        if let video = item as? AppVideo {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as! VideoCell
            cell.configure(with: video)
            return cell
        } else if let image = item as? AppImage {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
            cell.configure(with: image)
            return cell
        }
        
        fatalError("Unknown cell type")
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let item = dataSource[indexPath.item]
            
            let detailVC: UIViewController
            if let video = item as? AppVideo {
                detailVC = VideoDetailViewController(video: video)
            } else if let image = item as? AppImage {
                detailVC = ImageDetailViewController(image: image)
            } else {
                return
            }
            
            let navController = UINavigationController(rootViewController: detailVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ListViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if selectedCategory == .image {
            return CGSize(width: (view.frame.width - 30) / 2, height: 200)
        } else {
            let width = collectionView.bounds.width - 32
            return CGSize(width: width, height: 72)
        }
    }
}
