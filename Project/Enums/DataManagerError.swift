//
//  DataManagerError.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 02/11/2024.
//

import Foundation

enum DataManagerError: Error {
    case duplicateAsset
    case thumbnailGenerationFailed
    case invalidMediaType
    case saveFailed
    case fetchFailed
    
    var localizedDescription: String {
        switch self {
        case .duplicateAsset:
            return "Asset already exists"
        case .thumbnailGenerationFailed:
            return "Failed to generate thumbnail"
        case .invalidMediaType:
            return "Unsupported media type"
        case .saveFailed:
            return "Failed to save to Core Data"
        case .fetchFailed:
            return "Failed to fetch data"
        }
    }
}
