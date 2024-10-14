//
//  ListViewController.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 14/10/2024.
//

import UIKit
import CoreData

import UIKit
import CoreData

// MARK: - ListViewController

class ListViewController: UIViewController {
    
    // MARK: - Properties
    
    var selectedCategory: CategoryType?
    private var collectionView: UICollectionView!
    private var dataSource: [NSManagedObject] = []
    private var noDataLabel: UILabel!
    
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // Set the navigation title based on the category
        if let selectedCategory = selectedCategory {
            switch selectedCategory {
            case .image:
                title = "All Images"
            case .video:
                title = "All Videos"
            }
        }
        
        setupCollectionView()
        setupNoDataLabel()
        loadData()
    }
    
    // MARK: - UI Setup
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Register cells for video and image
        collectionView.register(VideoCell.self, forCellWithReuseIdentifier: "VideoCell")
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        
        view.addSubview(collectionView)
    }
    
    private func setupNoDataLabel() {
        noDataLabel = UILabel()
        noDataLabel.text = "No data available for this category."
        noDataLabel.textAlignment = .center
        noDataLabel.textColor = .gray
        noDataLabel.isHidden = true
        view.addSubview(noDataLabel)
        
        // Auto layout for noDataLabel
        noDataLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noDataLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noDataLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        guard let category = selectedCategory else { return }
        
        switch category {
        case .video:
            let videoFetchRequest: NSFetchRequest<AppVideo> = AppVideo.fetchRequest()
            
            do {
                let videos = try context.fetch(videoFetchRequest)
                dataSource = videos as [NSManagedObject]
            } catch {
                print("Error fetching videos: \(error)")
            }
            
        case .image:
            let imageFetchRequest: NSFetchRequest<AppImage> = AppImage.fetchRequest()
            
            do {
                let images = try context.fetch(imageFetchRequest)
                dataSource = images as [NSManagedObject]
            } catch {
                print("Error fetching images: \(error)")
            }
        }
        
        // Sort the dataSource by title
        dataSource.sort {
            ($0.value(forKey: "title") as? String ?? "") < ($1.value(forKey: "title") as? String ?? "")
        }
        
        updateUI()
    }
    
    // MARK: - UI Update
    
    private func updateUI() {
        if dataSource.isEmpty {
            collectionView.isHidden = true
            noDataLabel.isHidden = false
        } else {
            collectionView.isHidden = false
            noDataLabel.isHidden = true
            collectionView.reloadData()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ListViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 20 // Accounting for left and right insets
        return CGSize(width: width, height: 200) // Adjust height as needed
    }
}

// MARK: - UICollectionViewDelegate

extension ListViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
}

// MARK: - UICollectionViewDataSource

extension ListViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = dataSource[indexPath.item]
        
        if item is AppVideo {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as! VideoCell
            cell.configure(with: item as! AppVideo)
            return cell
        } else if item is AppImage {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
            cell.configure(with: item as! AppImage)
            return cell
        }
        
        fatalError("Unknown cell type")
    }
}
