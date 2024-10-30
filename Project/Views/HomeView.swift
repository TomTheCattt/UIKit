//
//  HomeView.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 30/10/2024.
//

import Foundation
import UIKit
import CoreData

class HomeView: UIView {
    // MARK: - Properties
    weak var delegate: HomeViewDelegate?
    private let categories = [CategoryType.image, CategoryType.video]
    
    // MARK: - UI Elements
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = DefaultValue.Colors.secondaryColor
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MediaCell.self, forCellReuseIdentifier: "MediaCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var navigationBar: UIView = {
        let nav = UIView()
        nav.backgroundColor = DefaultValue.Colors.primaryColor
        nav.translatesAutoresizingMaskIntoConstraints = false
        return nav
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = DefaultValue.String.homeViewTitle.uppercased()
        label.font = .boldSystemFont(ofSize: DefaultValue.FontSizes.titleFontSize)
        label.textColor = DefaultValue.Colors.accentColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var menuButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: DefaultValue.Icon.threeLineHorizontalIcon)
        button.setImage(image, for: .normal)
        button.tintColor = DefaultValue.Colors.accentColor
        button.addTarget(self, action: #selector(menuButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup
extension HomeView {
    // MARK: - Setup Views
    private func setupViews() {
        backgroundColor = DefaultValue.Colors.secondaryColor
        addSubview(navigationBar)
        navigationBar.addSubview(titleLabel)
        navigationBar.addSubview(menuButton)
        addSubview(tableView)
    }
    
    // MARK: - Setup Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Navigation Bar
            navigationBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            navigationBar.heightAnchor.constraint(equalToConstant: 44),
            
            // Menu Button
            menuButton.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor, constant: 16),
            menuButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            menuButton.widthAnchor.constraint(equalToConstant: 24),
            menuButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Title Label
            titleLabel.centerXAnchor.constraint(equalTo: navigationBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            
            // Table View
            tableView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

// MARK: - Actions
extension HomeView {
    @objc private func menuButtonTapped() {
        delegate?.homeViewDidTapMenu()
    }
}

// MARK: - UITableViewDataSource
extension HomeView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: MediaCell.reuseIdentifier,
            for: indexPath
        ) as? MediaCell else {
            return UITableViewCell()
        }
        
        cell.configure(with: categories[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension HomeView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedCategory = categories[indexPath.row]
        delegate?.homeView(didSelectCategory: selectedCategory)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

// MARK: - Protocol
protocol HomeViewDelegate: AnyObject {
    func homeViewDidTapMenu()
    func homeView(didSelectCategory category: CategoryType)
    func homeViewDidFinishFetching(_ result: FetchResult)
}
