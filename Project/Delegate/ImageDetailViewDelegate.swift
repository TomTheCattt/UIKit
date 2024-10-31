//
//  ImageDetailViewDelegate.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 01/11/2024.
//

import Foundation

/// Defines the method for handling interactions with the image detail view
protocol ImageDetailViewDelegate: AnyObject {
    /// Notifies the delegate that the image detail view should be dismissed
    /// - Parameter view: The image detail view requesting dismissal
    func imageDetailViewDidRequestDismiss(_ view: ImageDetailView)
}
