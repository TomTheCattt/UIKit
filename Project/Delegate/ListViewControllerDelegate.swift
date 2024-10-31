//
//  ListViewControllerDelegate.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 14/10/2024.
//

import Foundation

/// Defines the method to notify how many item was update
protocol ListViewControllerDelegate: AnyObject {
    func listViewController(_ controller: ListViewController, didUpdateItemCount count: Int, forCategory category: CategoryType)
}

