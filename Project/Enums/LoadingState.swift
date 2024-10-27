//
//  LoadingState.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 27/10/2024.
//

import Foundation

enum LoadingState {
    case idle
    case loading(progress: Float)  // 0.0 to 1.0
    case completed(updated: Int, skipped: Int)
    case error(String)
}
