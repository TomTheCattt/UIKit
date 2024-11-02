import UIKit

/// A custom view that displays a collection of items, handles no data situations,
/// shows loading indicators, and includes a bottom bar with a delete button.
final class ListView: UIView {
    // MARK: - UI Components
    /// The collection view used to display items.
    private(set) var collectionView: UICollectionView!
    
    /// A label shown when there is no data available to display.
    private(set) var noDataLabel: UILabel!
    
    /// An activity indicator to show loading status.
    private(set) var loadingIndicator: UIActivityIndicatorView!
    
    /// A view that contains the bottom bar elements.
    private(set) var bottomBar: UIView!
    
    /// The delete button located in the bottom bar.
    private(set) var deleteButton: UIButton!
    
    /// A constraint to manage the bottom position of the bottom bar.
    private(set) var bottomBarBottomConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    /// Initializes the view with a specified frame.
    ///
    /// - Parameter frame: The frame for the view.
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    /// Initializes the view from a storyboard or xib.
    ///
    /// - Parameter coder: A decoder to use for initialization.
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - UI Setup
    /// Sets up the initial UI components for the view.
    private func setupUI() {
        backgroundColor = .systemBackground
        setupCollectionView()
        setupNoDataLabel()
        setupLoadingIndicator()
        setupBottomBar()
    }
    
    /// Configures the collection view and adds it to the view hierarchy.
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 2
        
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = DefaultValue.Colors.secondaryColor
        
        addSubview(collectionView)
    }
    
    /// Configures the label displayed when there is no data available.
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
    
    /// Configures the loading indicator that shows progress while loading data.
    private func setupLoadingIndicator() {
        loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    /// Configures the bottom bar containing the delete button.
    private func setupBottomBar() {
        bottomBar = UIView()
        bottomBar.backgroundColor = .systemBackground
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomBar)
        
        deleteButton = UIButton(type: .system)
        deleteButton.backgroundColor = .systemGray4
        deleteButton.setTitleColor(.white, for: .normal)
        deleteButton.layer.cornerRadius = 8
        deleteButton.isEnabled = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
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
    
    // MARK: - Public Methods
    /// Updates the layout of the collection view based on the selected category.
    ///
    /// - Parameter category: The category type to update the layout for.
    func updateCollectionViewLayout(for category: CategoryType) {
        let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        
        if category == .image {
            layout?.minimumInteritemSpacing = 0
            layout?.minimumLineSpacing = 2
        } else {
            layout?.minimumLineSpacing = 50
            layout?.minimumInteritemSpacing = 0
        }
    }
    
    /// Updates the delete button's title and enabled state based on the item count.
    ///
    /// - Parameters:
    ///   - count: The number of items to delete.
    ///   - category: The category type of the items.
    func updateDeleteButton(count: Int, category: CategoryType) {
        let itemType = category == .image ? "image" : "video"
        let buttonTitle = "Delete \(count) \(itemType)\(count > 1 ? "s" : "")"
        
        deleteButton.setTitle(buttonTitle, for: .normal)
        deleteButton.backgroundColor = count > 0 ? .systemRed : .systemGray4
        deleteButton.isEnabled = count > 0
    }
    
    /// Shows the bottom bar with an optional animation.
    ///
    /// - Parameter animated: A Boolean value indicating whether the showing should be animated.
    func showBottomBar(animated: Bool = true) {
        layoutIfNeeded()
        bottomBarBottomConstraint?.constant = 0
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                self.layoutIfNeeded()
            }
        }
    }
    
    /// Hides the bottom bar with an optional animation.
    ///
    /// - Parameter animated: A Boolean value indicating whether the hiding should be animated.
    func hideBottomBar(animated: Bool = true) {
        layoutIfNeeded()
        bottomBarBottomConstraint?.constant = 100
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
                self.layoutIfNeeded()
            }
        }
    }
}
