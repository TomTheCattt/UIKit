import UIKit
import CoreData
import Photos

// MARK: - HomeViewController
/// `HomeViewController` manages the home screen of the application, allowing users to view and interact with media categories (images and videos).
class HomeViewController: UIViewController {
    
    // MARK: - Properties
    /// A delegate conforming to `HomeViewControllerDelegate` for handling menu actions.
    weak var delegate: HomeViewControllerDelegate?
    
    /// An array of `CategoryType` representing the types of media available (images and videos).
    private let categories = [CategoryType.image, CategoryType.video]
    
    /// A `DataManager` instance for handling media data operations.
    private lazy var dataManager: DataManager = {
        DispatchQueue.main.sync {
            return DataManager(context: CoreDataManager.shared.context, mediaType: nil)
        }
    }()
    
    /// A state variable indicating the current loading state of the view (idle, loading, completed, error).
    var loadingState: LoadingState = .idle {
        didSet {
            loadingStateDidChange?(loadingState)
        }
    }
    
    /// A closure that gets called when the loading state changes, allowing UI updates.
    var loadingStateDidChange: ((LoadingState) -> Void)?
    
    // MARK: - UI Element
    /// The main view for the home screen, containing UI elements for displaying media categories.
    private let homeView = HomeView()

    // MARK: - Lifecycle
    /// Called after the view has been loaded into memory. Sets up the navigation bar, binds the view model, and initializes the table view.
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        bindViewModel()
        setupTableView()
    }
    
    /// Called when the view's layout has changed. Adjusts the frame of `homeView` to match the view's bounds.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        homeView.frame = view.bounds
    }
}

// MARK: - UI Setup
extension HomeViewController {
    
    /// Configures the navigation bar with buttons for the side menu and refresh action.
    private func setupNavigationBar() {
        title = DefaultValue.String.homeViewTitle.uppercased()
        
        let sideMenuButton = UIBarButtonItem(image: UIImage(systemName: DefaultValue.Icon.threeLineHorizontalIcon),
                                             style: .plain,
                                             target: self,
                                             action: #selector(showSideMenu))
        navigationItem.leftBarButtonItem = sideMenuButton
        
        let refreshButton = UIBarButtonItem(image: UIImage(systemName: DefaultValue.Icon.reloadIcon),
                                            style: .plain,
                                            target: self,
                                            action: #selector(refreshAllData))
        navigationItem.rightBarButtonItem = refreshButton
    }
    
    /// Initializes the table view to display media categories.
    private func setupTableView() {
        view.addSubview(homeView)
        homeView.tableView.delegate = self
        homeView.tableView.dataSource = self
        homeView.tableView.register(MediaCell.self, forCellReuseIdentifier: MediaCell.reuseIdentifier)
    }
    
    /// Binds the loading state changes to update the UI accordingly.
    private func bindViewModel() {
        loadingStateDidChange = { [weak self] state in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch state {
                case .idle:
                    self.homeView.showLoading(false)
                    
                case .loading(let progress):
                    self.homeView.showLoading(true)
                    self.homeView.progressView.isHidden = false
                    self.homeView.progressView.progress = progress
                    
                case .completed(let updated, let skipped):
                    self.homeView.showLoading(false)
                    self.homeView.tableView.reloadData()
                    self.showAlert(title: "Success", message: "Updated \(updated) items.\nSkipped \(skipped) duplicates.")
                    
                case .error(let message):
                    self.homeView.showLoading(false)
                    self.showAlert(title: "Error", message: message)
                }
            }
        }
    }
    
    /// Fetches assets from the photo library and saves them using the data manager.
    private func fetchAndSaveAllAssets() {
        loadingState = .loading(progress: 0)
        
        let fetchOptions = PHFetchOptions()
        let imageAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let videoAssets = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        
        var allAssets: [PHAsset] = []
        imageAssets.enumerateObjects { (asset, _, _) in
            allAssets.append(asset)
        }
        videoAssets.enumerateObjects { (asset, _, _) in
            allAssets.append(asset)
        }
        
        dataManager.saveMediaFromAssets(allAssets) { processed, total in
            let progress = Float(processed) / Float(total)
            self.loadingState = .loading(progress: progress)
        } completion: { result in
            switch result {
            case .success(let completion):
                self.loadingState = .completed(updated: completion.totalProcessed, skipped: completion.totalSkipped)
            case .failure(let error):
                self.loadingState = .error(error.localizedDescription)
            }
        }
    }
}

// MARK: - Table Setup
extension HomeViewController: UITableViewDataSource {
    
    /// Returns the number of rows in the table view.
    /// - Parameters:
    ///   - tableView: The table view requesting this information.
    ///   - section: The index of the section.
    /// - Returns: The number of rows in the section.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    /// Configures and returns the cell for a given row in the table view.
    /// - Parameters:
    ///   - tableView: The table view requesting the cell.
    ///   - indexPath: The index path of the cell.
    /// - Returns: The configured `MediaCell`.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MediaCell.reuseIdentifier, for: indexPath) as? MediaCell else {
            return UITableViewCell()
        }
        
        cell.configure(with: categories[indexPath.row])
        return cell
    }
}

// MARK: - Table Interaction
extension HomeViewController: UITableViewDelegate {
    
    /// Handles the selection of a row in the table view.
    /// - Parameters:
    ///   - tableView: The table view containing the selected row.
    ///   - indexPath: The index path of the selected row.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedCategory = categories[indexPath.row]
        
        let backButton = UIBarButtonItem()
        backButton.title = ""
        navigationItem.backBarButtonItem = backButton
        
        let listViewController = ListViewController()
        listViewController.selectedCategory = selectedCategory
        listViewController.delegate = self
        navigationController?.pushViewController(listViewController, animated: true)
    }
    
    /// Returns the height of a row in the table view.
    /// - Parameters:
    ///   - tableView: The table view requesting this information.
    ///   - indexPath: The index path of the row.
    /// - Returns: The height of the row.
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

// MARK: - Action
extension HomeViewController {
    
    /// Displays the side menu when the side menu button is tapped.
    @objc private func showSideMenu() {
        delegate?.didTapMenuButton()
    }
}

// MARK: - Delegate
extension HomeViewController: ListViewControllerDelegate {
    
    /// Updates the item count in the table view when changes are made in the `ListViewController`.
    /// - Parameters:
    ///   - controller: The `ListViewController` instance.
    ///   - count: The updated item count.
    ///   - category: The category for which the count has been updated.
    func listViewController(_ controller: ListViewController, didUpdateItemCount count: Int, forCategory category: CategoryType) {
        if let indexPath = categories.firstIndex(of: category).map({ IndexPath(row: $0, section: 0) }) {
            if let cell = homeView.tableView.cellForRow(at: indexPath) as? MediaCell {
                cell.configure(with: category)
            }
        }
    }
}

// MARK: - Data Methods
extension HomeViewController {
    
    /// Refreshes all data by requesting access to the photo library and fetching assets.
    @objc private func refreshAllData() {
        requestPhotoLibraryAccess { [weak self] granted in
            guard let self = self else { return }
            
            if granted {
                self.fetchAndSaveAllAssets()
            } else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "Permission to access photo library is required")
                }
            }
        }
    }
}

// MARK: - Photos Library Permission
extension HomeViewController {
    
    /// Requests access to the photo library and returns the result through the completion handler.
    /// - Parameter completion: A closure that returns a Boolean indicating whether access was granted.
    private func requestPhotoLibraryAccess(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            completion(status == .authorized)
        }
    }
}

// MARK: - Alert Method
extension HomeViewController {
    
    /// Displays an alert with a title and message.
    /// - Parameters:
    ///   - title: The title of the alert.
    ///   - message: The message displayed in the alert.
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}

