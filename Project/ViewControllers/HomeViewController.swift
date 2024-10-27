//
//  HomeViewController.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 13/10/2024.
//

import Foundation

import UIKit
import CoreData
import Photos

// MARK: - HomeViewController
class HomeViewController: UIViewController {
    // MARK: - Properties
    weak var delegate: HomeViewControllerDelegate?
    
    private let categories = [CategoryType.image, CategoryType.video]
    
    private lazy var dataManager: ListViewDataManager = {
        DispatchQueue.main.sync {
            return ListViewDataManager(context: CoreDataManager.shared.context, mediaType: nil)
        }
    }()
    
    var loadingState: LoadingState = .idle {
        didSet {
            loadingStateDidChange?(loadingState)
        }
    }
    
    var loadingStateDidChange: ((LoadingState) -> Void)?
    
    // MARK: UI Element(s)
    private let tableView = UITableView()
    private let loadingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.isHidden = true
        return view
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        return indicator
    }()
    
    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.isHidden = true
        return progress
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setupTableView()
        setupLoadingView()
        setupProgressView()
        bindViewModel()
    }
}

// MARK: - UI Setup
extension HomeViewController {
    
    private func setupNavigationBar() {
        title = "Home"
        
        let sideMenuButton = UIBarButtonItem(image: UIImage(systemName: "line.horizontal.3"),
                                             style: .plain,
                                             target: self,
                                             action: #selector(showSideMenu))
        navigationItem.leftBarButtonItem = sideMenuButton
        
        let refreshButton = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"),
                                            style: .plain,
                                            target: self,
                                            action: #selector(refreshAllData))
        navigationItem.rightBarButtonItem = refreshButton
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(MediaCell.self, forCellReuseIdentifier: MediaCell.reuseIdentifier)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupLoadingView() {
        view.addSubview(loadingView)
        loadingView.addSubview(activityIndicator)
        
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor)
        ])
    }
    
    private func setupProgressView() {
        loadingView.addSubview(progressView)
        
        NSLayoutConstraint.activate([
            progressView.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            progressView.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
            progressView.widthAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func showLoading(_ show: Bool) {
        loadingView.isHidden = !show
        if show {
            activityIndicator.startAnimating()
            view.isUserInteractionEnabled = false
        } else {
            activityIndicator.stopAnimating()
            view.isUserInteractionEnabled = true
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func bindViewModel() {
        loadingStateDidChange = { [weak self] state in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch state {
                case .idle:
                    self.showLoading(false)
                    self.progressView.isHidden = true
                    
                case .loading(let progress):
                    self.showLoading(true)
                    self.progressView.isHidden = false
                    self.progressView.progress = progress
                    
                case .completed(let updated, let skipped):
                    self.showLoading(false)
                    self.progressView.isHidden = true
                    self.tableView.reloadData()
                    self.showAlert(title: "Success",
                                   message: "Updated \(updated) items.\nSkipped \(skipped) duplicates.")
                    
                case .error(let message):
                    self.showLoading(false)
                    self.progressView.isHidden = true
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
                self.loadingState = .completed(updated: completion.totalProcessed,
                                               skipped: completion.totalSkipped)
            case .failure(let error):
                self.loadingState = .error(error.localizedDescription)
            }
        }
    }
    
}

// MARK: - Table Setup
extension HomeViewController: UITableViewDataSource {
    // MARK: - UITableViewDataSource
    
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
    
    // MARK: - UITableViewDelegate
    
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
    
    // MARK: - Side Menu Action
    @objc private func showSideMenu() {
        delegate?.didTapMenuButton()
    }
}

// MARK: - Delegate
extension HomeViewController: ListViewControllerDelegate {
    func listViewController(_ controller: ListViewController, didUpdateItemCount count: Int, forCategory category: CategoryType) {
        if let indexPath = categories.firstIndex(of: category).map({ IndexPath(row: $0, section: 0) }) {
            if let cell = tableView.cellForRow(at: indexPath) as? MediaCell {
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
                    self.showAlert(title: "Error",
                                   message: "Permission to access photo library is required")
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



