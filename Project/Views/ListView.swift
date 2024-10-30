import UIKit
import Photos
import CoreData

protocol ListViewDelegate: AnyObject {
    func updateDataSource()
    func deleteItem()
}

class ListView: UIView {
    weak var delegate: ListViewDelegate?
    var selectedCategory: CategoryType?
    private var dataManager: DataManager!
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDataManager()
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupDataManager() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        dataManager = DataManager(
            context: appDelegate.persistentContainer.viewContext,
            mediaType: selectedCategory?.rawValue
        )
    }
    
    private func setupUI() {
        setupCollectionView()
        setupNavigationBar()
        setupNoDataLabel()
        setupLoadingIndicator()
        setupBottomBar()
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
        
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = DefaultValue.Colors.secondaryColor
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let cellIdentifier = selectedCategory == .image ? "ImageCell" : "VideoCell"
        let cellClass = selectedCategory == .image ? ImageCell.self : VideoCell.self
        collectionView.register(cellClass, forCellWithReuseIdentifier: cellIdentifier)
        
        addSubview(collectionView)
    }
    
    private func setupNavigationBar() {
        // There's no navigation bar in a UIView, so this is not applicable
    }
    
    private func setupBottomBar() {
        addSubview(bottomBar)
        bottomBar.addSubview(deleteButton)
        
        let bottomConstraint = bottomBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 100)
        bottomBarBottomConstraint = bottomConstraint
        
        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: trailingAnchor),
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
        addSubview(noDataLabel)
        
        noDataLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noDataLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            noDataLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    private func setupLoadingIndicator() {
        addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

// MARK: - Collection View Setup
extension ListView: UICollectionViewDelegate {
    
}

extension ListView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        <#code#>
    }
}

// MARK: - Actions
extension ListView {
    @objc private func selectAllTapped() {
            isUserInteractionEnabled = false
            
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
                self.layoutIfNeeded()
            }) { _ in
                self.isUserInteractionEnabled = true
            }
        }
    
    @objc private func cancelSelectionTapped() {
            isUserInteractionEnabled = false
            
            isSelectionModeEnabled = false
            selectedItems.removeAll()
            
            UIView.animate(withDuration: 0.2, animations: {
//                self.navigationItem.leftBarButtonItems = nil
//                self.navigationItem.rightBarButtonItems = [self.selectButton]
                
                self.bottomBarBottomConstraint?.constant = 100
                
                self.collectionView.visibleCells.forEach { cell in
                    if let imageCell = cell as? ImageCell {
                        imageCell.setSelectionMode(false, isSelected: false)
                    } else if let videoCell = cell as? VideoCell {
                        videoCell.setSelectionMode(false, isSelected: false)
                    }
                }
                
                self.layoutIfNeeded()
            }) { _ in
                self.isUserInteractionEnabled = true
            }
            
            updateDeleteButtonState()
        }
    
    @objc private func toggleSelectionMode() {
            isSelectionModeEnabled.toggle()
            
            UIView.animate(withDuration: 0.3) {
                self.updateUIForSelectionMode()
                self.layoutIfNeeded()
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
//                navigationItem.rightBarButtonItems = []
//                navigationItem.leftBarButtonItems = [cancelButton]
//                navigationItem.rightBarButtonItems = [selectAllButton]
//                showBottomBar()
            } else {
//                navigationItem.leftBarButtonItems = nil
//                navigationItem.rightBarButtonItems = [selectButton]
//                hideBottomBar()
//                selectedItems.removeAll()
            }
//            updateDeleteButtonState()
        }
    
    @objc private func deleteSelectedItems() {
            let message = "Are you sure you want to delete \(selectedItems.count) selected items?"
            let alert = UIAlertController(title: "Confirm Delete", message: message, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                //self?.performDeletion()
//            })
            
            //present(alert, animated: true)
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
