import UIKit
import CoreData
import Photos

// MARK: - HomeViewController
class HomeViewController: UIViewController {
    // MARK: - Properties
    weak var delegate: HomeViewControllerDelegate?
    
    private let categories = [CategoryType.image, CategoryType.video]
    
    private lazy var dataManager: DataManager = {
        DispatchQueue.main.sync {
            return DataManager(context: CoreDataManager.shared.context, mediaType: nil)
        }
    }()
    
    var loadingState: LoadingState = .idle {
        didSet {
            loadingStateDidChange?(loadingState)
        }
    }
    
    var loadingStateDidChange: ((LoadingState) -> Void)?
    
    // MARK: - UI Element
    private let homeView = HomeView()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        bindViewModel()
        setupTableView()
//        let coreData = CoreDataManager.shared
//        coreData.printCount()
//        coreData.printAllAppMedia()
        //coreData.deleteAllAppMedia()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        homeView.frame = view.bounds // Ensure the homeView takes the full size of the parent view
    }
}

// MARK: - UI Setup
extension HomeViewController {
    
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
    
    private func setupTableView() {
        view.addSubview(homeView)
        homeView.tableView.delegate = self
        homeView.tableView.dataSource = self
        homeView.tableView.register(MediaCell.self, forCellReuseIdentifier: MediaCell.reuseIdentifier)
    }
    
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

// MARK: - Action
extension HomeViewController {
    
    @objc private func showSideMenu() {
        delegate?.didTapMenuButton()
    }
}

// MARK: - Delegate
extension HomeViewController: ListViewControllerDelegate {
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
    
    private func fetchCoreDataItems() {
        dataManager.fetchData { result in
            switch result {
            case .success(let items):
                print("Fetched items:")
                items.forEach { item in
                    print(item)  // Customize this print as needed for specific attributes
                }
            case .failure(let error):
                print("Failed to fetch items: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Photos Library Permission
extension HomeViewController {
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
