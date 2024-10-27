//
//  Album.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 13/10/2024.
//

import Foundation

enum CategoryType: String {
    case image
    case video
    
    var mediaType: String {
        return self.rawValue
    }
    
    var title: String {
        switch self {
        case .image: return "Images"
        case .video: return "Videos"
        }
    }
    
    var systemIconName: String {
        switch self {
        case .image: return "photo"
        case .video: return "video"
        }
    }
}
