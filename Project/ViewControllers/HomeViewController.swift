//
//  HomeViewController.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 13/10/2024.
//

import Foundation

import UIKit

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



