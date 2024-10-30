//
//  ListViewController.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 30/10/2024.
//

import Foundation
import UIKit
import CoreData

class ListViewController: UIViewController {
    private let listView = ListView()
    var category: CategoryType?
    private var dataManager: DataManager!
    private var dataSource: [NSManagedObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDataManager()
    }
}

// MARK: - Setup
extension ListViewController {
    private func setupDataManager() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        dataManager = DataManager(context: appDelegate.persistentContainer.viewContext, mediaType: category?.rawValue)
    }
    
    private func setupView() {
        view.addSubview(listView)
        listView.translatesAutoresizingMaskIntoConstraints = false
    }
}
