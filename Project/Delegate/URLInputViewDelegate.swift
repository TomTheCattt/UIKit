//
//  URLInputViewDelegate.swift
//  Project
//
//  Created by Việt Anh Nguyễn on 14/10/2024.
//

import Foundation

protocol URLInputViewDelegate: AnyObject {
    func urlInputViewDidCancel(_ inputView: URLInputView)
    func urlInputView(_ inputView: URLInputView, didEnterURL urlString: String)
}
