//
//  HomeViewController.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 13/10/2024.
//

import Foundation

import UIKit
import CoreData

// MARK: - HomeViewController

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    weak var delegate: HomeViewControllerDelegate?
    
    // Table view to display categories
    private let tableView = UITableView()
    
    // Categories for the home view
    private let categories = [CategoryType.image, CategoryType.video]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the view
        setupNavigationBar()
        setupTableView()
    }
    
    // MARK: - UI Setup
    
    private func setupNavigationBar() {
        // Set the title of the Home View
        title = "Home"
        
        // Add a button to the navigation bar to show the side menu
        let sideMenuButton = UIBarButtonItem(image: UIImage(systemName: "line.horizontal.3"), style: .plain, target: self, action: #selector(showSideMenu))
        navigationItem.leftBarButtonItem = sideMenuButton
        
        // Thêm nút xóa tất cả dữ liệu Core Data
            let deleteButton = UIBarButtonItem(title: "Xóa Tất Cả", style: .plain, target: self, action: #selector(didTapDeleteAllButton))
            navigationItem.rightBarButtonItem = deleteButton
    }
    
    private func setupTableView() {
        // Add table view to the view hierarchy
        view.addSubview(tableView)
        
        // Set the delegate and data source
        tableView.delegate = self
        tableView.dataSource = self
        
        // Register a default UITableViewCell for reuse
        tableView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.reuseIdentifier)
        
        // Set constraints for the table view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CategoryCell.reuseIdentifier, for: indexPath) as? CategoryCell else {
            return UITableViewCell()
        }
        
        // Configure the cell with the corresponding category
        cell.configure(with: categories[indexPath.row])
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect the row with animation
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Get the selected category
        let selectedCategory = categories[indexPath.row]
        
        // Customize the back button
        let backButton = UIBarButtonItem()
        backButton.title = ""
        navigationItem.backBarButtonItem = backButton
        
        // Navigate to ListViewController with the selected category
        let listViewController = ListViewController()
        listViewController.selectedCategory = selectedCategory
        listViewController.delegate = self 
        navigationController?.pushViewController(listViewController, animated: true)
    }
    
    // Customize row height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    // MARK: - Side Menu Action
    
    @objc private func showSideMenu() {
        // Logic to show the side menu
        delegate?.didTapMenuButton()
    }
}
// MARK: - HomeViewController Extension
extension HomeViewController: ListViewControllerDelegate {
    func listViewController(_ controller: ListViewController, didUpdateItemCount count: Int, forCategory category: CategoryType) {
        // Since we're already on the main thread from ListViewController's callback,
        // we can directly update the UI
        if let indexPath = categories.firstIndex(of: category).map({ IndexPath(row: $0, section: 0) }) {
            if let cell = tableView.cellForRow(at: indexPath) as? CategoryCell {
                cell.configure(with: category)
            }
        }
    }
}

// MARK: - Core Data Deletion
extension HomeViewController {
    
    // Hàm được gọi khi bấm vào nút "Xóa Tất Cả"
    @objc private func didTapDeleteAllButton() {
        // Hiển thị thông báo xác nhận trước khi xóa
        let alert = UIAlertController(title: "Xóa Tất Cả Dữ Liệu", message: "Bạn có chắc chắn muốn xóa tất cả dữ liệu không?", preferredStyle: .alert)
        
        let deleteAction = UIAlertAction(title: "Xóa", style: .destructive) { [weak self] _ in
            self?.deleteAllData()
        }
        let cancelAction = UIAlertAction(title: "Hủy", style: .cancel, handler: nil)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    // Hàm xóa tất cả dữ liệu từ Core Data
    private func deleteAllData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        // Thực thể cần xóa
        let entities = ["AppVideo", "AppImage"] // Thay thế bằng tên các thực thể Core Data của bạn
        
        for entity in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                // Lấy tất cả các thực thể để xóa file
                let results = try context.fetch(fetchRequest) as! [NSManagedObject]
                for result in results {
                    if let filepath = result.value(forKey: "filepath") as? String {
                        // Xóa file từ thư mục Documents
                        self.deleteFile(at: filepath)
                    }
                }
                
                // Thực hiện xóa dữ liệu trong Core Data
                try context.execute(deleteRequest)
                try context.save()
                print("Đã xóa tất cả dữ liệu từ \(entity)")
            } catch let error as NSError {
                print("Không thể xóa dữ liệu: \(error), \(error.userInfo)")
            }
        }
        
        // Xóa cache của Core Data
        let persistentStoreCoordinator = appDelegate.persistentContainer.persistentStoreCoordinator
        for store in persistentStoreCoordinator.persistentStores {
            do {
                try persistentStoreCoordinator.remove(store)
                try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: store.url, options: nil)
                print("Đã reset lại Persistent Store.")
            } catch {
                print("Không thể reset lại Persistent Store: \(error)")
            }
        }
        
        // Cập nhật giao diện người dùng sau khi xóa
        tableView.reloadData()
    }
    
    private func deleteFile(at path: String) {
        let fileURL = URL(fileURLWithPath: path)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("Đã xóa file tại: \(path)")
        } catch {
            print("Không thể xóa file: \(error)")
        }
    }

}


